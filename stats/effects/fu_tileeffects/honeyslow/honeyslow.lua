function init()
  activateVisualEffects()
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.6,
      runModifier = 0.6,
      jumpModifier = 0.83
    })
end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=edcd5c=0.2")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function uninit()

end