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
		if not world.breathable(worldMouthPos) then
			local dummy=status.statusProperty("biomeairlesscooldown")
			if not dummy or ((os.time()-dummy)>=300) then
				world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
				status.setStatusProperty("biomeairlesscooldown",os.time())
			end
		end
	end
end
