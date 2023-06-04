function init()
  animator.setParticleEmitterOffsetRegion("dripspus", mcontroller.boundBox())
  if (mcontroller.liquidPercentage() < 0.30) then
    animator.setParticleEmitterActive("dripspus", true)
  else
    animator.setParticleEmitterActive("dripspus", false)
  end

  effect.setParentDirectives("fade=0072ff=0.1")
end

function update(dt)
  if (mcontroller.liquidPercentage() < 0.30) then  --only apply when submerged
	animator.setParticleEmitterActive("dripspus", true)
  else
	animator.setParticleEmitterActive("dripspus", false)
  end
  mcontroller.controlModifiers({
      runModifier = 0.87,
      jumpModifier = 0.87
  })
end