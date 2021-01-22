function init()
	previousPercent=1.0
	currentPercent=1.0
	script.setUpdateDelta(status.isResource("energy") and 5 or 0)
	self.healingRate = 1.0 / config.getParameter("energyTime", 10)
	effect.addStatModifierGroup({
	  {stat = "maxEnergy", effectiveMultiplier = 1.25},
	  {stat = "energyRegenBlockTime", effectiveMultiplier = 0.85}
	})
end

function update(dt)
	if status.isResource("energy") then
		currentPercent=status.resourcePercentage("energy")
		if currentPercent > previousPercent then
			status.modifyResourcePercentage("energy", self.healingRate * dt)
		end
		previousPercent=currentPercent
	end
end

function uninit()

end
