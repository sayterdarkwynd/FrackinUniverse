function update(dt)
	if not world.breathable(world.entityMouthPosition(entity.id())) then
		if not status.isResource("biomeairlesswarning") or not status.resourcePositive("biomeairlesswarning") then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
		end
		if status.isResource("biomeairlesswarning") then
			status.setResourcePercentage("biomeairlesswarning",1) 
		end
	end
end
