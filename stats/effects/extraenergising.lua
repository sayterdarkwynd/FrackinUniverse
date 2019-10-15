function init()
	previousPercent=1.0
	currentPercent=1.0
	script.setUpdateDelta(5)
	self.healingRate = 1.0 / config.getParameter("energyTime", 10)
end

function update(dt)
	currentPercent=status.resourcePercentage("energy")
	if currentPercent > previousPercent then
		status.modifyResourcePercentage("energy", self.healingRate * dt)
	end
	previousPercent=currentPercent
end

function uninit()
  
end
