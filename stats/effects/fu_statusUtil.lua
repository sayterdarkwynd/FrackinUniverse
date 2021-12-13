function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	return math.floor(math.min(world.lightLevel(position),1.0) * 100)
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
end

function nighttimeCheck()
	return world.timeOfDay() >= 0.5 -- true if night
end

function checkFood()
	return (((status.statusProperty("fuFoodTrackerHandler",0)>-1) and status.isResource("food")) and status.resource("food"))
end

function checkFoodPercent()
	return (((status.statusProperty("fuFoodTrackerHandler",0)>-1) and status.isResource("food")) and status.resourcePercentage("food"))
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end
