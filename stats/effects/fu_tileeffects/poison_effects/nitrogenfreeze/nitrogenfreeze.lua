function init()
	animator.setParticleEmitterOffsetRegion("snow", mcontroller.boundBox())
	animator.setParticleEmitterActive("snow", true)
	script.setUpdateDelta(5)
	self.tickTime = 0.7
	self.tickTimer = self.tickTime
	self.baseDamage = config.getParameter("healthDown",0)
end

function update(dt)
		if ( status.stat("iceResistance")	>= 0.75 ) then
		effect.expire()
	end
	mcontroller.controlModifiers({
				groundForce = 60.5,
				slopeSlidingFactor = 0.6,
				groundMovementModifier = 0.45,
				runModifier = 0.65,
				jumpModifier = 0.75
		})

	mcontroller.controlParameters({
			normalGroundFriction = 4.675
		})

	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		status.applySelfDamageRequest({
				damageType = "IgnoresDef",
				damage = self.baseDamage,
				damageSourceKind = "hoarfrost",
				sourceEntityId = entity.id()
			})
	end

	effect.setParentDirectives("fade=66FFFF="..self.tickTimer * 0.4)
end