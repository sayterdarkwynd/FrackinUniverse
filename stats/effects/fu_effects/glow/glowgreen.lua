function init()
  animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparkles", true)
  effect.setParentDirectives("fade=11cc11;0.00?border=0;11cc1100;00000000")
end

function update(dt)
  
end

function uninit()
  
end