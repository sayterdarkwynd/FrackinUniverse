require "/scripts/vec2.lua"
function init()
	script.setUpdateDelta(5)
end

function update(dt)
	local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	local liquidId = mcontroller.liquidId()
	if (not inWater) and world.liquidAt(mouthPosition) and (liquidId == 2) or (liquidId == 8) then
		status.setPersistentEffects("lavahealing", {
			{stat = "physicalResistance", amount = 0.25},
			{stat = "maxEnergy", baseMultiplier = 1.25},
			{stat = "maxHealth", baseMultiplier = 1.25}
		})
		inWater = true
	elseif inWater then
		status.clearPersistentEffects("lavahealing")
		inWater = false
	end
end
