function init()
	script.setUpdateDelta(5)
	self.tickTime = 0.5
	self.tickTimer = self.tickTime
	self.baseDamage = config.getParameter("healthDown",0)
	activateVisualEffects()
	-- Initial damage on touch.
	shrubbery=status.applySelfDamageRequest({
		damageType = "IgnoresDef",
		damage = self.baseDamage,
		damageSourceKind = "fire",
		sourceEntityId = entity.id()
	})
end

function deactivateVisualEffects()
	animator.setParticleEmitterActive("drips", false)
end

function activateVisualEffects()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	if entity.entityType()=="player" then
	local statusTextRegion = { 0, 1, 0, 1 }
	animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
	animator.burstParticleEmitter("statustext")
	end
end

function update(dt)
		if ( status.stat("fireResistance")	>= 1.0 ) then
			deactivateVisualEffects()
		effect.expire()
	end
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.baseDamage = self.baseDamage + 3
		self.tickTimer = self.tickTime
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = self.baseDamage,
			damageSourceKind = "fireplasma",
			sourceEntityId = entity.id()
		})
	end

	effect.setParentDirectives("fade=AA00AA="..self.tickTimer * 0.25)
end

function onExpire()
	status.addEphemeralEffect("burning")
end

function uninit()
	if shrubbery then
		effect.removeStatModifierGroup(shrubbery)
		shrubbery=nil
	end
end