function init()
  effect.addStatModifierGroup({
    {stat = "lavaImmunity", amount = 1},
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "fireResistance", amount = 0.2},
    {stat = "iceResistance", amount = 0.2},
    {stat = "biomecoldImmunity", amount = 1},
    {stat = "biomeheatImmunity", amount = 1}
  })
  script.setUpdateDelta(0)
end

function update(dt)
end

function uninit()
end