function init()
	--script.setUpdateDelta(30)
	setParticleConfig()
	script.setUpdateDelta(1)
end


--[[function activateVisualEffects()
	if world.entityType(entity.id()) ~= "player" then
		effect.expire()
	end
	--animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
	--animator.setParticleEmitterActive("smoke", true)
end]]


function setParticleConfig()
	particleConfig={type = "textured",image = "/animations/insanity/insanityfx.png",velocity = {0, 0},approach = {0, 0},destructionAction = "fade",size = 1,layer = "front",variance = {initialVelocity = {0, 0}}}
	local dt=script.updateDt()
	particleConfig.timeToLive = dt*10.0
	particleConfig.destructionTime = dt*5.0
end


function update(dt)
	if world.entityType(entity.id()) ~= "player" then
		effect.expire()
	end
	particleConfig.position=entity.position()
	world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
	--animator.setParticleEmitterActive("smoke", true)
end


function uninit()
	--animator.setParticleEmitterActive("smoke", false)
end
