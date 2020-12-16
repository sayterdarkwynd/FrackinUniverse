function init()
  animator.setParticleEmitterOffsetRegion("dripshealing", mcontroller.boundBox())
  if (mcontroller.liquidPercentage() < 0.30) then
    animator.setParticleEmitterActive("dripshealing", true)
  else
    animator.setParticleEmitterActive("dripshealing", false)
  end

  effect.setParentDirectives("fade=2244ff=0.1")
end

function update(dt)
  if (mcontroller.liquidPercentage() < 0.30) then  --only apply when submerged
	animator.setParticleEmitterActive("dripshealing", true)
  else
	animator.setParticleEmitterActive("dripshealing", false)
  end
  mcontroller.controlModifiers({
      runModifier = 0.97,
      jumpModifier = 0.97
  })
end