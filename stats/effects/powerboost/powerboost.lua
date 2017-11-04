function init()
  local alpha = math.floor(config.getParameter("alpha") * 255)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}})
  effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", amount = -1},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 0}
    })
  local bounds = mcontroller.boundBox()
 
    self.powerModifier = (status.resource("energy")/100) + (status.resource("health")/100)
    sb.logInfo("the bonus ="..self.powerModifier)  
    effect.addStatModifierGroup({
      {stat = "powerMultiplier", baseMultiplier = 1 + self.powerModifier}
    })
    
  script.setUpdateDelta(5)
end

function update(dt)
  mcontroller.controlModifiers({speedModifier = 0.75})
end