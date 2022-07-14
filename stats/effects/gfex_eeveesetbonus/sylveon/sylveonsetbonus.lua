function init()
  effect.addStatModifierGroup({{stat = "shadowResistance", amount = 0.15}})
  script.setUpdateDelta(5)
  self.healingRate = 1.0 / 150
  
  effect.addStatModifierGroup({
    {stat = "energyRegenPercentageRate", amount = 10},
    {stat = "energyRegenBlockTime", effectiveMultiplier = 0}
  })
end

function update(dt)
  status.modifyResourcePercentage("health", self.healingRate * dt)
end

function uninit()
end
