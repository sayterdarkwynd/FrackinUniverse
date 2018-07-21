function init()
end

function update(dt)
	if not doOnce then
		timerVar=(timerVar or 0)+dt
		if timerVar>1.0 then
			world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeairless", 1.0)
			doOnce=true
		end
	end
end

function uninit()
end
