function init()
  animator.setParticleEmitterOffsetRegion("drips", mcontroller.boundBox())
  if (mcontroller.liquidPercentage() < 0.30) then
    animator.setParticleEmitterActive("drips", true)
  else
    animator.setParticleEmitterActive("drips", false)
  end
  
  effect.setParentDirectives("fade=0072ff=0.1")
end

function update(dt)
  if (mcontroller.liquidPercentage() < 0.30) then  --only apply when submerged
	animator.setParticleEmitterActive("drips", true)
  else
	animator.setParticleEmitterActive("drips", false)
  end
  mcontroller.controlModifiers({
      runModifier = 0.97,
      jumpModifier = 0.97
  })   
end