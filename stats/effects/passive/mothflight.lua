require "/stats/effects/fu_statusUtil.lua"

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