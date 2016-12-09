function init()
  effect.setParentDirectives("border=2;003a0011;00000000")
  effect.addStatModifierGroup({
    {stat = "slushslowImmunity", amount = 1},
    {stat = "iceslipImmunity", amount = 1},
    {stat = "snowslowImmunity", amount = 1},
    {stat = "ffextremecoldImmunity", amount = 1},
    {stat = "iceResistance", amount = 0.15}
  })
end

function update(dt)
end

function uninit()
  
end