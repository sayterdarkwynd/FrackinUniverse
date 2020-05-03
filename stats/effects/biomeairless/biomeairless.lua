require "/scripts/vec2.lua"

function update(dt)
	local worldMouthPos=vec2.add(entity.position(),status.statusProperty("mouthPosition") or {0,0})
	worldMouthPos[1]=world.xwrap(worldMouthPos[1])

	if not world.breathable(worldMouthPos) then
		if not status.isResource("biomeairlesswarning") or not status.resourcePositive("biomeairlesswarning") then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
		end
		if status.isResource("biomeairlesswarning") then
			status.setResourcePercentage("biomeairlesswarning",1) 
		end
	end
end
