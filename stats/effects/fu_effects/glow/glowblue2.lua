function init()
  animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparkles", true)
  effect.setParentDirectives("fade=93BCEF;0.00?border=0;93BCEF00;00000000")
end

function update(dt)
  
end

function uninit()
  
end