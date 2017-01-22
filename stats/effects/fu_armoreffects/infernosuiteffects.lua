function init()
  effect.addStatModifierGroup({
    {stat = "ffextremeheatImmunity", amount = 1},
    {stat = "biomeheatImmunity", amount = 1},
    {stat = "biomecoldImmunity", amount = 1},
    {stat = "ffextremecoldImmunity", amount = 1},
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "fireResistance", amount = 0.55}
  })
end

function update(dt)
end

function uninit()

end
