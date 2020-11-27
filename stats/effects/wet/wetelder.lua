function init()
  animator.setParticleEmitterOffsetRegion("dripselder", mcontroller.boundBox())
  if (mcontroller.liquidPercentage() < 0.30) then
    animator.setParticleEmitterActive("dripselder", true)
  else
    animator.setParticleEmitterActive("dripselder", false)
  end

  effect.setParentDirectives("fade=337233=0.1")
end

function update(dt)
  if (mcontroller.liquidPercentage() < 0.30) then  --only apply when submerged
	animator.setParticleEmitterActive("dripselder", true)
  else
	animator.setParticleEmitterActive("dripselder", false)
  end
  mcontroller.controlModifiers({
      runModifier = 0.77,
      jumpModifier = 0.77
  })
end