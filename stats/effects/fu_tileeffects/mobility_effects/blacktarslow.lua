function init()
  activateVisualEffects()
end

function update(dt)
  mcontroller.controlModifiers({
      groundMovementModifier = 0.4,
      runModifier = 0.4,
      airJumpModifier = 0.45
    })
end

function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=300030=0.8")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

function uninit()

end