function init()
  script.setUpdateDelta(5)
 -- effect.addStatModifierGroup({{stat = "powerMultiplier", basePercentage = -0.3}})
 -- effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", basePercentage = 0.15}})
 -- effect.addStatModifierGroup({{stat = "energyRegenBlockDischarge", basePercentage = 10}})
  effect.addStatModifierGroup({{stat = "energyRegenPercentageRate", baseMultiplier = effect.configParameter("regenAmount", 0)}})
  effect.addStatModifierGroup({{stat = "energyRegenBlockDischarge", baseMultiplier = effect.configParameter("regenBlockAmount", 0)}}) 
end





