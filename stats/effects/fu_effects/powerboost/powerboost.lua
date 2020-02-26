function init()
  applyTechBonus()
  local alpha = math.floor(config.getParameter("alpha") * 255)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}})
  effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", amount = -1},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 0}
    })
    self.powerModifier = (status.resource("energy")/100) + (status.resource("health")/100) + 0.25
    effect.addStatModifierGroup({
      {stat = "powerMultiplier", effectiveMultiplier = (1 + self.powerModifier) * self.damageBonus}
    })
    
  script.setUpdateDelta(5)
end

function applyTechBonus()
  self.damageBonus = 1 + status.stat("powerboosttechBonus",0) -- apply bonus from certain items and armor
end

function update(args)
  mcontroller.controlModifiers({speedModifier = 0.75})
end