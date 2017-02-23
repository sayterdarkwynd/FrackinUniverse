function init()
  script.setUpdateDelta(5)
  effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", baseMultiplier = config.getParameter("regenAmount", 0)}})
  effect.addStatModifierGroup({{stat = "energyRegenBlockTime", baseMultiplier = config.getParameter("regenBlockAmount", 0)}}) 
end





