function init()
	object.setInteractive(false)
	if storage.state == nil then
		output(false)
	else
		output(storage.state)
	end
	if storage.timer == nil then
		storage.timer = 0
	end
	self.interval = config.getParameter("interval")
	message.setHandler("precursorkeyprimary",function()output(true)end)
end

function update(dt)
	if storage.timer > 0 then
		storage.timer = storage.timer - dt

		if storage.timer <= 0 then
			output(false)
		end
	end
end

function state()
	return storage.state
end

function output(state)
	laststate=storage.state
	storage.state = state

	if state ~= laststate then
		if state then
			animator.playSound("on")
			storage.timer = self.interval
		else
			animator.playSound("off")
		end
	 end

	object.setAllOutputNodes(state)
	if not (config.getParameter("alwaysLit")) then object.setLightColor(config.getParameter((state and "lightColor") or "lightColorOff", {0, 0, 0, 0})) end
	animator.setAnimationState("switchState",(state and "on") or "off")
	object.setSoundEffectEnabled(state)
end
