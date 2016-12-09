function init()
  effect.setParentDirectives("border=2;003a0011;00000000")
  effect.addStatModifierGroup({
    {stat = "breathProtection", amount = 1},
    {stat = "shadowgasImmunity", amount = 1},
    {stat = "protoImmunity", amount = 1},
    {stat = "waterbreathProtection", amount = 1},
    {stat = "biomecoldImmunity", amount = 1},
    {stat = "iceResistance", amount = 0.15}
  })
end

function update(dt)
end

function uninit()
  
end