function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
end

function update(dt)
  mcontroller.controlModifiers({
      speedModifier = 0.89,
      airJumpModifier = 0.84
    })
end

function uninit()

end