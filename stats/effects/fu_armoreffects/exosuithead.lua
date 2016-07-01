function init()
  script.setUpdateDelta(5)
  --- energyRegenPercentageRate base = 0.285
  --- energyRegenBlockDischarge base = -1.0
  effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", amount = 1.05}})
  effect.addStatModifierGroup({{stat = "energyRegenBlockDischarge", amount = -2}})
end

function update(dt)
end

function uninit()

end
