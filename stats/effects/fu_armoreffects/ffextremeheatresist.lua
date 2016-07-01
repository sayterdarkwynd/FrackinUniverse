function init()
  effect.setParentDirectives("border=2;003a0011;00000000")
  effect.addStatModifierGroup({
    {stat = "ffextremeheatImmunity", amount = 1},
    {stat = "biomeheatImmunity", amount = 1},
    {stat = "fireImmunity", amount = 1}
  })
end

function update(dt)
end

function uninit()
  
end