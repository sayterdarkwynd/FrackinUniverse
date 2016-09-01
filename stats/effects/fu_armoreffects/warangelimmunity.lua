function init()
  effect.setParentDirectives("border=2;003a0011;00000000")
  effect.addStatModifierGroup({
    {stat = "ffextremeradiationImmunity", amount = 1},
    {stat = "biomeradiationImmunity", amount = 1},
    {stat = "ffextremeheatImmunity", amount = 1},
    {stat = "biomeheatImmunity", amount = 1},
    {stat = "ffextremecoldImmunity", amount = 1},
    {stat = "biomecoldImmunity", amount = 1},
    {stat = "sulphuricImmunity", amount = 1},
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "nitrogenfreezeImmunity", amount = 1},
    {stat = "breathProtection", amount = 1},
    {stat = "poisonStatusImmunity", amount = 1},
    {stat = "extremepressureProtection", amount = 1}
  })
end

function update(dt)
end

function uninit()
  
end