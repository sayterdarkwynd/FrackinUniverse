function init(virtual)
	if virtual == true then return end
	storage.active = storage.active or false
end

function update(dt)

end

function isn_getCurrentPowerOutput(divide)
	local divisor = isn_countPowerDevicesConnectedOnOutboundNode(0)
	local voltage = isn_getCurrentPowerInput(true)
	if divide and divisor > 0 then return voltage / divisor
	else return voltage end
end

function onNodeConnectionChange()
	if isn_checkValidOutput() then object.setOutputNodeLevel(0, true)
	else object.setOutputNodeLevel(0, false) end
end

function onInputNodeChange(args)
	storage.active = object.isInputNodeConnected(0) and object.getInputNodeLevel(0)
end