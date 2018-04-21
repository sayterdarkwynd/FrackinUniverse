function init()
	-- Heal percent is the configParameter in the json statuseffects file
	self.healingRate = config.getParameter("healPercent", 0) / effect.duration()	
end

function update(dt)
	status.modifyResourcePercentage("health", self.healingRate * dt)
end
