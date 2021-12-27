function init()
	animator.setParticleEmitterOffsetRegion("flames", mcontroller.boundBox())
	animator.setParticleEmitterActive("flames", true)
	effect.setParentDirectives("fade=FF8800=0.2")

	script.setUpdateDelta(5)

	self.tickTimer = 1.0
	self.ticks=0
	
	if ( status.stat("fireResistance")	>= 1.0 ) then
		effect.expire()
		return
	end

	status.applySelfDamageRequest({
		damageType = "IgnoresDef",
		damage = damageValue(),
		damageSourceKind = "fire",
		sourceEntityId = entity.id()
	})
end

function damageValue()
	return (math.max(0,1-status.stat("fireResistance"))*(((status.statPositive("specialStatusImmunity") and 5) or 30)+(5*self.ticks)))
end

function update(dt)
	if ( status.stat("fireResistance")	>= 1.0 ) then
		effect.expire()
		return
	end
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.ticks=(self.ticks or 0)+1
		if status.statPositive("specialStatusImmunity") then
			self.ticks=math.min(self.ticks,world.threatLevel())
		end
		self.tickTimer = 1.0
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = damageValue(),
			damageSourceKind = "fire",
			sourceEntityId = entity.id()
		})
	end
end

function onExpire()
	status.addEphemeralEffect("burning")
end
