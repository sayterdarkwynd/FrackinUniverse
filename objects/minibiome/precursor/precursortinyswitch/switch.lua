function init()
	object.setInteractive(false)
	if storage.state == nil then
		output(config.getParameter("defaultSwitchState", false))
	else
		output(storage.state)
	end
	message.setHandler("precursorkeyprimary",function()output(true)end)
	message.setHandler("precursorkeyalt",function()output(false)end)
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
		else
			animator.playSound("off")
		end
	 end

	object.setAllOutputNodes(state)
	if not (config.getParameter("alwaysLit")) then object.setLightColor(config.getParameter((state and "lightColor") or "lightColorOff", {0, 0, 0, 0})) end
	animator.setAnimationState("switchState",(state and "on") or "off")
	object.setSoundEffectEnabled(state)
end
