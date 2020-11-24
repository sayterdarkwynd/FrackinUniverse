function init()
  self.species = world.entitySpecies(entity.id())
  if not self.species == "saturn" then
    effect.die()
  end
    self.healingRate = 1.01 / config.getParameter("healTime", 220)
    --food defaults
    hungerMax = { pcall(status.resourceMax, "food") }
    hungerMax = hungerMax[1] and hungerMax[2]
    hungerLevel = status.resource("food")
    baseValue = config.getParameter("healthDown",0)*(status.resourceMax("food"))
    self.tickTime = 1.0
    self.tickTimePenalty = 5.0
    self.tickTimer = self.tickTime
    self.tickTimerPenalty = self.tickTimePenalty
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
end

function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = math.min(world.lightLevel(position),1.0)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end


function update(dt)
  daytime = daytimeCheck()
  underground = undergroundCheck()
  local lightLevel = getLight()
	if status.isResource("food") then
		self.foodValue = status.resource("food")
		hungerLevel = status.resource("food")
	else
		self.foodValue = 50
		hungerLevel = 50
	end
    --food defaults
    hungerMax = { pcall(status.resourceMax, "food") }
    hungerMax = hungerMax[1] and hungerMax[2]

    baseValue = config.getParameter("healthDown",0)*(status.resourceMax("food"))
    self.tickTimer = self.tickTimer - dt
    self.tickTimerPenalty = self.tickTimerPenalty - dt
    self.foodValue = status.resource("food")

    if daytime and lightLevel then --if its day, a saturnian can regen their food if flying stationary. More light = more regen
		if (hungerLevel < hungerMax) and ( self.tickTimer <= 0 ) then
			self.tickTimer = self.tickTime
			adjustedHunger = hungerLevel + (lightLevel * 0.008)
			status.setResource("food", adjustedHunger)
		end
    end
    if not daytime and lightLevel >= 60 then --if its night and they are in bright light, a saturnian can regen their food if flying stationary
		if (hungerLevel < hungerMax) and ( self.tickTimer <= 0 ) then
			self.tickTimer = self.tickTime
			adjustedHunger = hungerLevel + (lightLevel * 0.0075)
			status.setResource("food", adjustedHunger)
		end
    end
end


function uninit()

end