function init()
  animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparkles", true)
  effect.setParentDirectives("fade=930000;0.00?border=0;00000000;00000000")
end

function update(dt)
  
end

function uninit()
  
end