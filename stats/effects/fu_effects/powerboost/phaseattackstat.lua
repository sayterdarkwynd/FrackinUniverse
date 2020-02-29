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

function applyTechBonus()
  self.damageBonus = 1 + status.stat("phaseattackBonus",0) -- apply bonus from certain items and armor
end

function update(dt)
  applyTechBonus()
  mcontroller.controlModifiers({speedModifier = 0.75})
  
  self.powerModifier = status.resource("energy")/status.stat("maxEnergy")
  if self.damageBonus > 1.0 then
	  effect.addStatModifierGroup({
	      {stat = "powerMultiplier", effectiveMultiplier = 2 * self.damageBonus - self.powerModifier}
	  })    
  else
	  effect.addStatModifierGroup({
	      {stat = "powerMultiplier", effectiveMultiplier = 2 - self.powerModifier}
	  })    
  end

  
end