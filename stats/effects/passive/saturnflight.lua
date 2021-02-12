function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
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
	local lightLevel = getLight()
	if status.statPositive("gliding") then
		if daytime and lightLevel then --if its day, a saturnian can regen their food if flying stationary. More light = more regen
			if status.isResource("food") then
				status.modifyResourcePercentage("food",(lightLevel * 0.0008 * dt))
			end
		end
		if not daytime and lightLevel >= 60 then --if its night and they are in bright light, a saturnian can regen their food if flying stationary
			if status.isResource("food") then
				status.modifyResourcePercentage("food",(lightLevel * 0.00075 * dt))
			end
		end
	end
end