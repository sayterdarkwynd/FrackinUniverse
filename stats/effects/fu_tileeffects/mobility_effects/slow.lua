require "/stats/effects/fu_statusUtil.lua"

function init()
	animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
	animator.setParticleEmitterActive("drips", true)

	--check types
	if config.getParameter("isHoney",0)==1 then
		activateVisualEffects("fade=edcd5c=0.2")
	end
	if config.getParameter("isTar",0)==1 then
		activateVisualEffects("fade=300030=0.8")
	end
	self.groundMovementModifier = config.getParameter("moveMod",1)
	self.speedModifier = config.getParameter("speedMod",1)
	self.airJumpModifier = config.getParameter("jumpMod",1)
end

function update(dt)
	applyFilteredModifiers({
		groundMovementModifier = self.groundMovementModifier,
		speedModifier = self.speedModifier,
		airJumpModifier = self.airJumpModifier
	})
end

function activateVisualEffects(directives)
	effect.setParentDirectives(directives)
	if entity.entityType()=="player" then
	animator.setParticleEmitterOffsetRegion("statustext", { 0, 1, 0, 1 })
	animator.burstParticleEmitter("statustext")
	end
end

function uninit()
	filterModifiers({},true)
end
