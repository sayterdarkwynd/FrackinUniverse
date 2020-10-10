function init()
	--script.setUpdateDelta(30)
	setParticleConfig(0)
	script.setUpdateDelta(1)
end


--[[function activateVisualEffects()
	if world.entityType(entity.id()) ~= "player" then
		effect.expire()
	end
	--animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
	--animator.setParticleEmitterActive("smoke", true)
end]]


function setParticleConfig(dt)
	if not particleConfig then
		particleConfig={type = "textured",image = "/animations/insanity/insanityfx.png",velocity = {0, 0},approach = {0, 0},destructionAction = "fade",size = 1,layer = "front",variance = {initialVelocity = {0, 0}}}
	end
	particleConfig.position=entity.position()
	particleConfig.timeToLive = dt*1.5
	particleConfig.destructionTime = dt*4.5
end


function update(dt)
	if world.entityType(entity.id()) ~= "player" then
		effect.expire()
	end
	setParticleConfig(dt)
	world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
	--animator.setParticleEmitterActive("smoke", true)
end


function uninit()
	--animator.setParticleEmitterActive("smoke", false)
end
