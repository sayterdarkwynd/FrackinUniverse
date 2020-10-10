require "/scripts/vec2.lua"

function init()
	initDelay=1.0
end

function update(dt)
	if not initDelay or initDelay>0 then
		initDelay=initDelay-dt
	else
		local worldMouthPos=vec2.add(entity.position(),status.statusProperty("mouthPosition") or {0,0})
		worldMouthPos[1]=world.xwrap(worldMouthPos[1])
		--sb.logInfo("%s",{ep=entity.position(),wmp=worldMouthPos,sspmp=status.statusProperty("mouthPosition") or {0,0},warn=((status.isResource("biomeairlesswarning") and status.resourcePositive("biomeairlesswarning")) or "not a resource"),eid=entity.id()})
		if not world.breathable(worldMouthPos) then
			if not status.isResource("biomeairlesswarning") or not status.resourcePositive("biomeairlesswarning") then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
			end
			if status.isResource("biomeairlesswarning") then
				status.setResourcePercentage("biomeairlesswarning",1) 
			end
		end
	end
end
