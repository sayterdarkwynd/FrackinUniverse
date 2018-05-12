function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
  effect.setParentDirectives("fade=0072ff=0.1")
end

function update(dt)
  mcontroller.controlModifiers({
      runModifier = 0.9,
      jumpModifier = 0.9
    })
end