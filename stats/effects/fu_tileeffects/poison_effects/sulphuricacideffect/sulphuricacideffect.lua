function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	script.setUpdateDelta(5)
	self.tickTime = 0.5
	self.tickTimer = self.tickTime
	self.baseDamage = config.getParameter("healthDown",0)
end

function update(dt)
		if ( status.stat("physicalResistance")	>= 0.90 ) then
		effect.expire()
	end
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = self.baseDamage,
			damageSourceKind = "corrosive",
			sourceEntityId = entity.id()
		})
	end
	effect.setParentDirectives("fade=00AA00="..self.tickTimer * 0.4)
end