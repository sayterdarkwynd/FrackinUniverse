function init()
  effect.addStatModifierGroup({
    {stat = "physicalResistance", amount = 1},
    {stat = "iceResistance", amount = 1},
    {stat = "fireResistance", amount = 1},
    {stat = "poisonResistance", amount = 1},
    {stat = "electricResitsance", amount = 1},
    {stat = "cosmicResistance", amount = 1},
    {stat = "radioactiveResistance", amount = 1},
    {stat = "shadowResistance", amount = 1}
  })
  animator.playSound("trolol")
end

function update(dt)
end

function uninit()
  
end