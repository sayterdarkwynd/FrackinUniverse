function init()
	warningResource="biomeairlesswarning"
	if status.isResource(warningResource) then
		if not status.resourcePositive(warningResource) then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
		end
		status.setResourcePercentage(warningResource,1.0)
	else
		world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
	end
end

function update(dt)
	if status.isResource(warningResource) then
		warningTimer=(warningTimer or 0)+dt
		if warningTimer>1 then
			status.setResourcePercentage(warningResource,1.0)
		end
	end
end
