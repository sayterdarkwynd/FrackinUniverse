function init()
	script.setUpdateDelta(5)
	self.tickTime = 1.0
	self.tickTimer = self.tickTime
	self.baseDamage = config.getParameter("healthDown",0)
	activateVisualEffects()
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

function deactivateVisualEffects()
	animator.setParticleEmitterActive("drips", false)
end

function update(dt)
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
		status.applySelfDamageRequest({
			damageType = "IgnoresDef",
			damage = self.baseDamage,
			damageSourceKind = "cosmic",
			sourceEntityId = entity.id()
		})
	end
	effect.setParentDirectives("fade=ff0000="..self.tickTimer * 0.4)
end

function uninit()
	if shrubbery then
		effect.removeStatModifierGroup(shrubbery)
		shrubbery=nil
	end
end