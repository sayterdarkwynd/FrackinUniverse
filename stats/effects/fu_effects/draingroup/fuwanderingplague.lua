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
	self.tickTime = 2.0
	--damage starts piddly, but ramps up as the effect goes on. this value is a percentage.
	self.baseDamage=config.getParameter("baseDamage",0.0007)
	--'hard' target damage is scaled by world tier, multiplied by base damage and any special scaling
	self.hardMult=config.getParameter("baseDamage",500)

	--30s internal timer, no refreshing
	local dur=effect.duration()
	self.duration=self.duration or math.min(30,dur)
	effect.modifyDuration(self.duration-dur)
	self.handler=effect.addStatModifierGroup({})
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
		self.stacks=(self.stacks or 0)+1
		effect.modifyDuration(self.duration-dur)
	end

	self.tickTimer = math.max(0,(self.tickTimer or self.tickTime) - dt)
	if self.tickTimer <= 0 then
		--damage starts off weak, but progressively ramps up
		local stacks=((self.stacks or 0)+math.max(1,(30.0-self.duration)/2))
		damageCalc=self.baseDamage*stacks
		--can't forget hard target distinction. percentage of health against beefy targets is broken, and not allowed.
		damageCalc=math.ceil((status.statPositive("specialStatusImmunity") and world.threatLevel()*damageCalc*self.hardMult) or (status.resourceMax("health") * damageCalc))

		effect.setStatModifierGroup(self.handler,{
			{stat="iceResistance",amount=-0.005*stacks},
			{stat="poisonResistance",amount=-0.005*stacks}
		})

		--effect uses two damage instances, this instance is frost and is covered by ice resistance
		local iceRes=status.stat("iceResistance")
		if iceRes <= 0.8 then
			local resMod=1.0
			if iceRes>0 then
				resMod=resMod+(iceRes)
			end
			status.applySelfDamageRequest({damageType = "IgnoresDef",damage = damageCalc*resMod,damageSourceKind = "hoarfrost",sourceEntityId = self.source})
		end

		--similar to the ice section, but this one is poison
		local poisonRes=status.stat("poisonResistance")
		if poisonRes <= 0.8 then
			local resMod=1.0
			if iceRes>0 then
				resMod=resMod+(poisonRes)
			end
			status.applySelfDamageRequest({damageType = "IgnoresDef",damage = damageCalc*resMod,damageSourceKind = "bioweapon",sourceEntityId = self.source})
			effect.setParentDirectives(string.format("fade=00AA00=%.1f", self.tickTimer * 0.4))
		end

		local comboRes=iceRes+poisonRes
		--bonus effect, hybrid resistance
		if comboRes < 0.80 then
			effectUtil.effectSelf("staffslow",self.tickTime*2,self.source)
		end

		--spread mechanic; if the subject lacks sufficient sum resistance, the effect spreads at the same duration, sourced to the same entity.
		if comboRes <= 1.0 then
			effectUtil.effectAllInRange("fuwanderingplague",16,self.duration,self.source)
		end
		self.tickTimer = self.tickTime
	end
end

function uninit()
	if self.handler then
		effect.removeStatModifierGroup(self.handler)
		self.handler=nil
	end
end