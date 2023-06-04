function init()
  animator.setParticleEmitterOffsetRegion("purple", mcontroller.boundBox())
  animator.setParticleEmitterActive("purple", true)
  animator.setParticleEmitterOffsetRegion("green", mcontroller.boundBox())
  animator.setParticleEmitterActive("green", true)
  if mcontroller.velocity()[2] <= 10 then
    mcontroller.setYVelocity(10.0)
  end
  effect.addStatModifierGroup({{stat = "fallDamageMultiplier", baseMultiplier = -2}})
end

function update(dt)
  mcontroller.controlParameters({ bounceFactor = 1 })
end

function uninit()

end