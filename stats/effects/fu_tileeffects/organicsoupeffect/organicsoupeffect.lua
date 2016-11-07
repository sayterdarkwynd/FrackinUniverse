function init()

  hungerMax = { pcall(status.resourceMax, "food") }
  hungerMax = hungerMax[1] and hungerMax[2]
  if not hungerMax then
    -- 'food' resource has no max; do nothing
    script.setUpdateDelta(0)
    return
  end
  
  hungerLevel = status.resource("food")
  _x = config.getParameter("healthDown", 0)
  baseValue = config.getParameter("healthDown",0)*(status.resourceMax("health"))
  
  if (status.resourceMax("health")) * _x >= 100.0 then
     effect.addStatModifierGroup({{stat = "maxHealth", amount = baseValue }})
  end
  
  effect.setParentDirectives("border=1;cc005500;00000000")
  script.setUpdateDelta(5)

  self.tickDamagePercentage = 0.0
  self.tickTime = 3.0
  self.tickTimer = self.tickTime  

end




function update(dt)
  if not hungerMax then return end -- belt and braces

  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
	  if (hungerLevel < hungerMax) then
	    adjustedHunger = hungerLevel + 0.2 -- decent rate, not too fast
	    status.setResource("food", adjustedHunger)
	  end    
  end

  effect.setParentDirectives("fade=aa00cc="..self.tickTimer * 0.4)

end

function uninit()
  
end
