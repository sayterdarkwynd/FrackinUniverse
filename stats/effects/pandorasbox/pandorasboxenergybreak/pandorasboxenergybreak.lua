function init()
	bonusHandler=effect.addStatModifierGroup({
		{stat = "energyRegenPercentageRate", effectiveMultiplier = 0},
		{stat = "energyRegenBlockTime", effectiveMultiplier = 0}
	})
end

function update(dt)
	if status.isResource("energy") then
		status.setResourceLocked("energy", true)
		status.setResourcePercentage("energy", 0)
	end
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
