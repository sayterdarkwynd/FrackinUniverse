
function init()
	resource1=config.getParameter("resource1","health")
	resource2=config.getParameter("resource2","food")
	efficient=config.getParameter("efficient",true)
	lethal=config.getParameter("lethal",true)--if this is true, efficient doesn't matter.
	ratio = config.getParameter("ratio", 1.0)--resource2 per resource1 (both percentages)
	flat = config.getParameter("flat")--healPercent is per second if this is true
	self.healingRate = config.getParameter("healPercent", 0)
	if not flat then
		self.healingRate=self.healingRate / effect.duration()
	end
end

function update(dt)
	if status.isResource(resource2) and ratio ~= 0.0 then
		if (not efficient) or lethal or status.resourcePercentage(resource1) < 1.0 then
			if status.consumeResource(resource2, status.resourceMax(resource2)*self.healingRate*dt*ratio) then
				status.modifyResourcePercentage(resource1, self.healingRate * dt)
			elseif lethal then
				status.modifyResourcePercentage(resource1, self.healingRate * dt*-1)
			end
		end
	else
		status.modifyResourcePercentage(resource1, self.healingRate*dt)
	end
end
