require "/stats/effects/fu_statusUtil.lua"

function init()
	script.setUpdateDelta(5)
	self.tickTime = 1.0
	self.tickTimer = self.tickTime
	self.baseDamage = config.getParameter("healthDown",0)
	activateVisualEffects()

	shrubbery=effect.addStatModifierGroup({
		{ stat = "shadowResistance", amount = -0.25*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "fireResistance", amount = -0.25*((status.statPositive("specialStatusImmunity") and 0.25) or 1) },
		{ stat = "iceResistance", amount = -0.25*((status.statPositive("specialStatusImmunity") and 0.25) or 1) }
	})
end

function activateVisualEffects()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)
	if entity.entityType()=="player" then
		animator.setParticleEmitterOffsetRegion("statustext", { 0, 1, 0, 1 })
		animator.burstParticleEmitter("statustext")
	end
end

function deactivateVisualEffects()
	animator.setParticleEmitterActive("drips", false)
end

function update(dt)
	if ( status.stat("poisonResistance") >= 0.5 ) then
		deactivateVisualEffects()
		effect.expire()
	end
	self.tickTimer = self.tickTimer - dt
	if self.tickTimer <= 0 then
		self.tickTimer = self.tickTime
	end
	applyFilteredModifiers({
		groundMovementModifier = 0.8,
		speedModifier = 0.8,
		airJumpModifier = 0.8
	})

	effect.setParentDirectives("fade=AA00AA="..self.tickTimer * 0.4)
end

function uninit()
	if shrubbery then
		effect.removeStatModifierGroup(shrubbery)
		shrubbery=nil
	end

	filterModifiers({},true)
end
