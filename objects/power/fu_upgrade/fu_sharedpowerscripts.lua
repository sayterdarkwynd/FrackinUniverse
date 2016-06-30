function isn_getCurrentPowerInput(divide)
	---world.logInfo("POWER INPUT DEBUG aka PID")
	---world.logInfo("called by " .. world.entityName(entity.id()))
	local totalInput = 0
	local iterator = 0
	local connectedDevices
	local output = 0
	
	local nodecount = entity.inboundNodeCount() 
	---world.logInfo("PID: nodecount is " .. nodecount)
	
	while iterator < nodecount do
		---world.logInfo("PID: Iteration " .. iterator)
		if entity.getInboundNodeLevel(iterator) == true then
			connectedDevices = isn_getAllDevicesConnectedOnNode(iterator,"inbound")
			for key, value in pairs (connectedDevices) do
				---world.logInfo("PID: key is " .. key)
				---world.logInfo("PID: value is " .. value)
				---world.logInfo("PID: value ID check resolves to " .. world.entityName(value))
				if world.callScriptedEntity(value,"isn_canSupplyPower") == true then
					output = world.callScriptedEntity(value,"isn_getCurrentPowerOutput",divide)
					---world.logInfo("PID: Power supplier detected with output of " .. output)
					if output ~= nil then totalInput = totalInput + output end
				else
					---world.logInfo("PID: Detected non power-supplying device")
				end
			end
		end
		---world.logInfo("PID: total input now at " .. totalInput)
		iterator = iterator + 1
	end
	
	---world.logInfo("GENERAL POWER INPUT DEBUG END")
	return totalInput
end

function isn_hasRequiredPower()
	local power = isn_getCurrentPowerInput(true)
	local requirement = entity.configParameter("isn_requiredPower")
	if power == nil then return false end
	if requirement == nil then return true end
	
	if power >= requirement then return true
	else return false end
end

function isn_canSupplyPower()
	if entity.configParameter("isn_powerSupplier") == true then return true
	else return false end
end

function isn_canRecievePower()
	if entity.configParameter("isn_powerReciever") == true then return true
	else return false end
end

function isn_doesNotConsumePower()
	if entity.configParameter("isn_freePower") == true then return true
	else return false end
end

function isn_checkValidOutput()
	local connectedDevices = isn_getAllDevicesConnectedOnNode(0,"outbound")
	if connectedDevices == nil then return false end
	for key, value in pairs(connectedDevices) do
		if world.callScriptedEntity(value,"isn_canRecievePower") == false then return false end
	end
	return true
end

function isn_countPowerDevicesConnectedOnOutboundNode(node)
	---world.logInfo("POWER DEVICE COUNT DEBUG BEGIN aka PDCDB")
	if node == nil then return 0 end
	local devicecount = 0
	local devicelist = isn_getAllDevicesConnectedOnNode(node,"outbound")
	if devicelist == nil then return 0 end
	---world.logInfo("PDCDB: iterating detected devices")
	for key, value in pairs(devicelist) do
		---world.logInfo("PDCDB: key is " .. key)
		---world.logInfo("PDCDB: value is " .. value)
		---local devicecheck = world.entityName(value)
		---if devicecheck == nil then
			---world.logInfo("PDCDB: value resolves to nil")
		---else
			---world.logInfo("PDCDB: value resolves to " .. devicecheck)
		---end
		if world.callScriptedEntity(value,"isn_canRecievePower") == true then
			if world.callScriptedEntity(value,"isn_doesNotConsumePower") == false then
				---world.logInfo("PDCDB: power-consuming device detected and added to count")
				devicecount = devicecount + 1
			end
		end
	end
	---world.logInfo("POWER DEVICE COUNT DEBUG END")
	return devicecount
end