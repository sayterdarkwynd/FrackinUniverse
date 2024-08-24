require "/stats/effects/fu_statusUtil.lua"

function init()
	activateVisualEffects()
	script.setUpdateDelta(1)
	setParticleConfig(0)
end

function update(dt)
	applyFilteredModifiers({
		groundMovementModifier = 0.75,
		speedModifier = 0.75,
		airJumpModifier = 0.65
	})
	setParticleConfig(dt)
	world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
end

function setParticleConfig(dt)
	if not particleConfig then
		particleConfig={type = "textured",image = "/animations/blur/blur2.png",destructionAction = "fade",size = 1,layer = "front",variance = {rotation=360,initialVelocity = {0.0, 0.0}}}
	end
	particleConfig.position=entity.position()
	particleConfig.timeToLive = dt*7.5
	particleConfig.destructionTime = dt*3.75
end

function activateVisualEffects()
	--animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
	--animator.setParticleEmitterActive("smoke", true)
	effect.setParentDirectives("fade=edcd5c=0.2")
	if entity.entityType()=="player" then
		local statusTextRegion = { 0, 1, 0, 1 }
		animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
		animator.burstParticleEmitter("statustext")
	end
end

function uninit()
	filterModifiers({},true)
end
