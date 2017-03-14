function init()
  effect.addStatModifierGroup({
    {stat = "breathProtection", amount = 1},
    {stat = "biooozeImmunity", amount = 1},
    {stat = "insanityImmunity", amount = 1},
    {stat = "beestingImmunity", amount = 1},
    {stat = "poisonStatusImmunity", amount = 1},
    {stat = "protoImmunity", amount = 1},
    {stat = "pusImmunity", amount = 1},
    {stat = "shadowResistance", amount = 0.5},
    {stat = "cosmicResistance", amount = 0.5},
    {stat = "poisonResistance", amount = 1},
    {stat = "radiationResistance", amount = 1},
    {stat = "iceResistance", amount = 1},
    {stat = "electricResistance", amount = 0.5},
    {stat = "fireResistance", amount = 1},
    {stat = "wetImmunity", amount = 1}
  })
end

function update(dt)
end

function uninit()
  
end