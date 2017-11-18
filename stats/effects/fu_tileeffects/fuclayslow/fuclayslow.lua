function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  animator.setParticleEmitterActive("drips", true)
end

function update(dt)
  mcontroller.controlModifiers({
      speedModifier = 0.79,
      airJumpModifier = 0.80
    })
end

function uninit()

end