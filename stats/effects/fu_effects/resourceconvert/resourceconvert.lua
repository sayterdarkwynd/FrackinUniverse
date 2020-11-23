
function init()
	resource1=config.getParameter("resource1","health")--the one to convert to
	resource2=config.getParameter("resource2","food")--the one to convert from
	
	efficient=config.getParameter("efficient",true)--efficient means it will not waste any resource.
	wasteful=config.getParameter("wasteful",false)--if this is true, efficient is ignored. will continually drain regardless.
	lethal=config.getParameter("lethal",false)--if this is true, efficient doesn't matter nor does wasteful. when the resource runs dry, it drains instead of restores.
	
	ratio = config.getParameter("ratio", 1.0)--resource2 per resource1 (both percentages)
	flat = config.getParameter("flat",false)--healPercent is per second instead of over the duration if this is false
	self.healingRate = config.getParameter("healPercent", 0)
	
	if (not flat) and effect.duration() and (effect.duration()>0) then
		self.healingRate=self.healingRate / effect.duration()
	end
	active=status.isResource(resource1) and status.isResource(resource2)
end

function update(dt)
	if active then
		if status.isResource(resource2) and ratio ~= 0.0 then
			if lethal or wasteful then
				if status.consumeResource(resource2, math.abs(status.resourceMax(resource2)*self.healingRate*dt*ratio)) then
					status.modifyResourcePercentage(resource1, self.healingRate * dt)
				elseif lethal then
					status.modifyResourcePercentage(resource1, self.healingRate * dt*-1)
				end
			elseif (not efficient) then
				if status.resourcePercentage(resource1)<1.0 then
					if status.consumeResource(resource2, math.abs(status.resourceMax(resource2)*self.healingRate*dt*ratio)) then
						status.modifyResourcePercentage(resource1, self.healingRate * dt)
					end
				end
			else
				local delta=math.min(1.0-status.resourcePercentage(resource1),self.healingRate*dt)/(self.healingRate*dt)
				if status.consumeResource(resource2, math.abs(status.resourceMax(resource2)*self.healingRate*dt*ratio*delta)) then
					status.modifyResourcePercentage(resource1, self.healingRate * dt  * delta)
				end
			end
		else
			status.modifyResourcePercentage(resource1, self.healingRate*dt)
		end
	end
end
