function init()
  if status.isResource("food") then
    hungerMax = { pcall(status.resourceMax, "food") }
    hungerMax = hungerMax[1] and hungerMax[2]
    hungerLevel = status.resource("food")
    baseValue = config.getParameter("healthDown",0)*(status.resourceMax("food"))

    effect.setParentDirectives("border=1;cc005500;00000000")
    self.tickDamagePercentage = 0.0
    self.tickTime = 3.0
    self.tickTimer = self.tickTime
    script.setUpdateDelta(3)
  else
    script.setUpdateDelta(0)
  end
end




function update(dt)
  hungerMax = { pcall(status.resourceMax, "food") }
  hungerMax = hungerMax[1] and hungerMax[2]
  healthMax = { pcall(status.resourceMax, "health") }
  healthMax = healthMax[1] and healthMax[2]
  hungerLevel = status.resource("food")
  healthLevel = status.resource("health")
  baseValue = config.getParameter("healthDown",0)*(status.resourceMax("food"))
  randVal = math.random(1,2)
  
  self.tickTimer = self.tickTimer - dt
  if self.tickTimer <= 0 then
    self.tickTimer = self.tickTime
    if randVal == 1 then
	  if (hungerLevel < hungerMax) then
	    adjustedHunger = hungerLevel + (hungerLevel * 0.015)
	    status.setResource("food", adjustedHunger)
	  end    
    else
	  if (healthLevel < healthMax) then
	    adjustedHealth = healthLevel + (healthLevel * 0.015*math.max(0,1+status.stat("healingBonus")))
	    status.setResource("health", adjustedHealth)
	  end    
    end

  end

  effect.setParentDirectives("fade=aa00cc="..self.tickTimer * 0.4)

end

function uninit()

end
