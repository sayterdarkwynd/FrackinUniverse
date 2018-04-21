function init()
  activateVisualEffects()
  local slows = status.statusProperty("slows", {})
  slows["booze2"] = 0.65
  status.setStatusProperty("slows", slows)
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.75,
      runModifier = 0.75,
      jumpModifier = 0.65
    })
end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("smoke", mcontroller.boundBox())
  animator.setParticleEmitterActive("smoke", true)
  effect.setParentDirectives("fade=edcd5c=0.2")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function uninit()
  local slows = status.statusProperty("slows", {})
  slows["booze2"] = nil
  status.setStatusProperty("slows", slows)
end