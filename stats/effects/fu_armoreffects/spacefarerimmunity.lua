function init()
  animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
  animator.setParticleEmitterActive("sparkles", true)
  effect.setParentDirectives("fade=F1EA9C;0.00?border=0;F1EA9C00;00000000")
  effect.addStatModifierGroup({
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "breathProtection", amount = 1},
    {stat = "slushslowImmunity", amount = 1},
    {stat = "protoImmunity", amount = 1},
    {stat = "liquidnitrogenImmunity", amount = 1},
    {stat = "nitrogenfreezeImmunity", amount = 1},
    {stat = "iceslipImmunity", amount = 1},
    {stat = "extremepressureProtection", amount = 1}
  })
end

function update(dt)
end

function uninit()
  
end