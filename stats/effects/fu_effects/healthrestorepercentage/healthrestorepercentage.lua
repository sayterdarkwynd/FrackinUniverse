function init()
	-- Heal percent is the configParameter in the json statuseffects file
	flat = config.getParameter("flat")--healPercent is per second if this is true
	self.healingRate = config.getParameter("healPercent", 0)
	if not flat then
		self.healingRate=self.healingRate / effect.duration()
	end	
end

function update(dt)
	status.modifyResourcePercentage("health", self.healingRate * dt)
end
