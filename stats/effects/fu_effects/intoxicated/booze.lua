function init()
	activateVisualEffects()
	local slows = status.statusProperty("slows", {})
	slows["booze"] = 0.55
	status.setStatusProperty("slows", slows)
	script.setUpdateDelta(1)
	setParticleConfig(0)
end

function update(dt)
	mcontroller.controlModifiers({
		groundMovementModifier = 0.85,
		runModifier = 0.85,
		jumpModifier = 0.82
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
	local slows = status.statusProperty("slows", {})
	slows["booze"] = nil
	status.setStatusProperty("slows", slows)
end