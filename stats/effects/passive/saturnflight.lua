require "/stats/effects/fu_statusUtil.lua"

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