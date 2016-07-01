function init()
  effect.setParentDirectives("border=2;003a0011;00000000")
  effect.addStatModifierGroup({
    {stat = "biomeradiationImmunity", amount = 1},
    {stat = "ffextremeradiationImmunity", amount = 1}
  })
end

function update(dt)
end

function uninit()
  
end