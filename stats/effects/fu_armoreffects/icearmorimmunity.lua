function init()
  effect.setParentDirectives("border=2;003a0011;00000000")
  effect.addStatModifierGroup({
    {stat = "liquidnitrogenImmunity", amount = 1},
    {stat = "nitrogenfreezeImmunity", amount = 1},
    {stat = "protoImmunity", amount = 1},
    {stat = "ffextremecoldImmunity", amount = 1}
  })
end

function update(dt)
end

function uninit()
  
end