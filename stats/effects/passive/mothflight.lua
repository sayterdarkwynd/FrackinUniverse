function init()
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
	return math.floor(math.min(world.lightLevel(position),1.0) * 100)
end

function update(dt)
	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()

	if (not daytime and (lightLevel <= 60)) or underground then --if its dark or underground, a saturnian can regen their food if its dark enough
		if status.isResource("food") then
			status.modifyResourcePercentage("food",(0.00075*dt))
		end
	end
	if not daytime and lightLevel >= 60 then --if its night and they are in bright light, a saturnian can regen their food
		if status.isResource("food") then
			status.modifyResourcePercentage("food",(lightLevel * 0.0007*dt))
		end
	end
end

function uninit()

end