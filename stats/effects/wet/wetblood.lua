function init()
  animator.setParticleEmitterOffsetRegion("dripsblood", mcontroller.boundBox())
  if (mcontroller.liquidPercentage() < 0.30) then
    animator.setParticleEmitterActive("dripsblood", true)
  else
    animator.setParticleEmitterActive("dripsblood", false)
  end

  effect.setParentDirectives("fade=ff0072=0.1")
end

function update(dt)
  if (mcontroller.liquidPercentage() < 0.30) then  --only apply when submerged
	animator.setParticleEmitterActive("dripsblood", true)
  else
	animator.setParticleEmitterActive("dripsblood", false)
  end
  mcontroller.controlModifiers({
      runModifier = 0.97,
      jumpModifier = 0.97
  })
end