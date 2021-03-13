require "/scripts/effectUtil.lua"

function init()
	--everything is sourced to this entity.
	self.source=effect.sourceEntity()
	--effect ends when the source is gone
	if (not world.entityExists(self.source)) or (not world.entityCanDamage(self.source,entity.id())) then
		script.setUpdateDelta(0)
		effect.expire()
		return
	else
		script.setUpdateDelta(5)
	end

	--damage ticks every second, and much of the effect is oriented around that.
	self.tickTime = 1.0
	--damage starts piddly, but ramps up as the effect goes on. at 0.0014, the effect will do approximately 40% of the target's health.
	self.baseDamage=config.getParameter("baseDamage",0.0014)
	
	--hard capped. 30s max duration.
	local dur=effect.duration()
	self.duration=self.duration or math.min(dur,30)
	effect.modifyDuration(self.duration-dur)
end

function update(dt)
	if (not self.source) then return end
	--source gone, effect gone, again.
	if (not world.entityExists(self.source)) or (not world.entityCanDamage(self.source,entity.id())) then
		effect.expire()
		return
	end

	--internal timer, with a 1s lockout where the effect is active but does nothing.
	local dur=effect.duration()
	self.duration=self.duration-dt
	if self.duration<=-1 then
		effect.expire()
		return
	elseif self.duration<=0 then
		effect.modifyDuration(1.0-dur)
		return
	end

	--check duration, if it's not within an expected range we reset it back to the correct duration.
	if (self.duration~=dur) and (math.abs(self.duration-dur)>(2*dt)) then
		effect.modifyDuration(1.0-dur)
	end

	--damage starts off weak, but progressively ramps up by about 5.5x at the end of the duration
	local damageCalc=self.baseDamage*math.sqrt(math.max(0.1,30-self.duration))
	--can't forget hard target distinction. percentage of health against beefy targets is broken, and not allowed.
	damageCalc=math.ceil((status.statPositive("specialStatusImmunity") and world.threatLevel*damageCalc*150) or (status.resourceMax("health") * damageCalc))

	--effect uses two damage instances, this instance is frost and is covered by ice resistance
	local iceRes=status.stat("iceResistance")
	self.tickTimer2 = math.max(0,(self.tickTimer2 or self.tickTime) - dt)
	if iceRes <= 0.8 then
		if self.tickTimer2 <= 0 then
			self.tickTimer2 = self.tickTime
			status.applySelfDamageRequest({damageType = "IgnoresDef",damage = damageCalc,damageSourceKind = "hoarfrost",sourceEntityId = self.source})
		end
	end

	--similar to the ice section, but this one is poison
	local poisonRes=status.stat("poisonResistance")
	self.tickTimer1 = math.max(0,(self.tickTimer1 or self.tickTime) - dt)
	if poisonRes <= 0.8 then
		if self.tickTimer1 <= 0 then
			self.tickTimer1 = self.tickTime
			status.applySelfDamageRequest({damageType = "IgnoresDef",damage = damageCalc,damageSourceKind = "bioweapon",sourceEntityId = self.source})
		end
		effect.setParentDirectives(string.format("fade=00AA00=%.1f", self.tickTimer1 * 0.4))
	end

	local comboRes=iceRes+poisonRes
	--bonus effect, hybrid resistance
	if comboRes < 0.80 then
		effectUtil.effectSelf("staffslow",self.tickTime*2,self.source)
	end

	--spread mechanic; if the subject lacks sufficient sum resistance, the effect spreads at the same duration, sourced to the same entity.
	if comboRes <= 1.0 then
		effectUtil.effectAllInRange("fuwanderingplague",30,self.duration,self.source)
	end
end

