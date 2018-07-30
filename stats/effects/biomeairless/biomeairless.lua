function init()
	warningResource="biomeairlesswarning"
	sendMessage(true)
end

function update(dt)
	sendMessage()
end

function sendMessage(force)
	if not world.breathable(entity.position()) then
		if status.isResource(warningResource) then
			if not status.resourcePositive(warningResource) then
				world.sendEntitysendMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
			end
			status.setResourcePercentage(warningResource,1.0)
		elseif force then
			world.sendEntitysendMessage(entity.id(), "queueRadioMessage", "biomeairless", 30.0)
		end
	end
end