function init()
  local bounds = mcontroller.boundBox()
  animator.setParticleEmitterOffsetRegion("jumpparticles", {bounds[1], bounds[2] + 0.2, bounds[3], bounds[2] + 0.3})
  effect.addStatModifierGroup({
    {stat = "ffextremeradiationImmunity", amount = 1},
    {stat = "biomeradiationImmunity", amount = 1},
    {stat = "sulphuricImmunity", amount = 1}
  })
end

function update(dt)
  animator.setParticleEmitterActive("jumpparticles", mcontroller.jumping())
  mcontroller.controlModifiers({
      jumpModifier = 1.20
    })
end

function uninit()
  
end