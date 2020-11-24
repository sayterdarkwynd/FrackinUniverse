function init()
	resource=config.getParameter("resource","health")
	-- Heal percent is the configParameter in the json statuseffects file
	flat = config.getParameter("flat")--healPercent is per second if this is true
	self.healingRate = config.getParameter("healPercent", 0)
	if not flat then
		self.healingRate=self.healingRate / effect.duration()
	end
end

function update(dt)
	if(status.isResource(resource)) then
		status.modifyResourcePercentage(resource, self.healingRate * dt)
	end
end
