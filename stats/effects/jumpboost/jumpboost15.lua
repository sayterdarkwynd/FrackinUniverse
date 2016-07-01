function init()
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("jumpparticles", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
end

function update(dt)
  animator.setParticleEmitterActive("jumpparticles", mcontroller.jumping())
  mcontroller.controlModifiers({
      jumpModifier = 1.15
    })
end

function uninit()
  
end