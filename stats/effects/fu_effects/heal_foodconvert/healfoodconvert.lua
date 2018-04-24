
function init()
	efficient=config.getParameter("efficient",true)
	lethal=config.getParameter("lethal",true)--if this is true, efficient doesn't matter.
	ratio = config.getParameter("ratio", 1.0)--food per health (both percentages)
	flat = config.getParameter("flat")--healPercent is per second if this is true
	self.healingRate = config.getParameter("healPercent", 0)
	if not flat then
		self.healingRate=self.healingRate / effect.duration()
	end
end

function update(dt)
	if status.isResource("food") and ratio ~= 0.0 then
		if (not efficient) or lethal or status.resourcePercentage("health") < 1.0 then
			if status.consumeResource("food", status.resourceMax("food")*self.healingRate*dt*ratio) then
				status.modifyResourcePercentage("health", self.healingRate * dt)
			elseif lethal then
				status.modifyResourcePercentage("health", self.healingRate * dt*-1)
			end
		end
	else
		status.modifyResourcePercentage("health", self.healingRate*dt)
	end
end
