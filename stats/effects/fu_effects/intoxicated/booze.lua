function init()
  activateVisualEffects()
  local slows = status.statusProperty("slows", {})
  slows["booze"] = 0.55
  status.setStatusProperty("slows", slows)
	script.setUpdateDelta(1)
	setParticleConfig()
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.85,
      runModifier = 0.85,
      jumpModifier = 0.82
    })
	particleConfig.position=entity.position()
	world.sendEntityMessage(entity.id(),"fu_specialAnimator.spawnParticle",particleConfig)
end

function setParticleConfig()
	particleConfig={type = "textured",image = "/animations/blur/blur2.png",velocity = {0, -2},approach = {15, 15},destructionAction = "shrink",size = 1,layer = front,variance = {initialVelocity = {1.0, 1.0}}}
	local dt=script.updateDt()
	particleConfig.timeToLive = dt*15
	particleConfig.destructionTime = dt*15.0
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