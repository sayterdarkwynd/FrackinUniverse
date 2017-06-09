function init()
	
	storage.active = storage.active or false
end

function update(dt)
	checkOutputsSetLevels()
end

function isn_getCurrentPowerOutput(divide)
	local divisor = isn_countPowerDevicesConnectedOnOutboundNode(0)
	local voltage = isn_getCurrentPowerInput(true)
	if voltage and divide and divisor > 0 then return voltage / divisor
	else return voltage end
end

function checkOutputsSetLevels()
	storage.active = (object.isInputNodeConnected(0) and object.getInputNodeLevel(0)) or (object.isInputNodeConnected(1) and object.getInputNodeLevel(1))
	animator.setAnimationState("switchState",(storage.active and "on") or "off")
	if isn_checkValidOutput() and storage.active then object.setOutputNodeLevel(0, true)
	else object.setOutputNodeLevel(0, false) end
end

function onNodeConnectionChange()
	checkOutputsSetLevels()
end

function onInputNodeChange(args)
	checkOutputsSetLevels()
end