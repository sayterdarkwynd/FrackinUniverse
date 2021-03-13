require "/scripts/effectUtil.lua"

function init()
	script.setUpdateDelta(5)
	self.tickTime = 3.0
	self.tickTimer = self.tickTime
	self.baseDamage = config.getParameter("healthDown",0)
	activateVisualEffects()

	shrubbery=effect.addStatModifierGroup({
		{ stat = "poisonResistance", amount = -self.baseDamage*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "mentalProtection", effectiveMultiplier = 0 }
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
	effectUtil.effectSelf("slimebioluminescence")
end

function update(dt)
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
	end
	if ( status.stat("physicalResistance")	>= 0.45 ) then
			deactivateVisualEffects()
			effect.expire()
	end
	effect.setParentDirectives("fade=88dd55="..self.tickTimer * 0.4)
end

function uninit()
	if shrubbery then
		effect.removeStatModifierGroup(shrubbery)
		shrubbery=nil
	end
end