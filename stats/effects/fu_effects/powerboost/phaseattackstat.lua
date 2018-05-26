function init()
  local alpha = math.floor(config.getParameter("alpha") * 255)
  effect.setParentDirectives(string.format("?multiply=ffffff%02x", alpha))
  effect.addStatModifierGroup({{stat = "invulnerable", amount = 1}})
  effect.addStatModifierGroup({
      {stat = "energyRegenPercentageRate", amount = -1},
      {stat = "energyRegenBlockTime", effectiveMultiplier = 0}
    })
   

  script.setUpdateDelta(40)
end

function update(dt)
  mcontroller.controlModifiers({speedModifier = 0.75})
  
  self.powerModifier = status.resource("energy")/status.stat("maxEnergy")
  effect.addStatModifierGroup({
      {stat = "powerMultiplier", baseMultiplier = 2 - self.powerModifier}
  })  

end