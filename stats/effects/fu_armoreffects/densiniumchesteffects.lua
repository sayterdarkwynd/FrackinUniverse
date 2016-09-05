function init()
  effect.addStatModifierGroup({
    {stat = "ffextremeheatImmunity", amount = 1},
    {stat = "biomeheatImmunity", amount = 1},
    {stat = "sulphuricImmunity", amount = 1},
    {stat = "protoImmunity", amount = 1},
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "extremepressureProtection", amount = 1}
  })
end

function update(dt)
end

function uninit()
  
end