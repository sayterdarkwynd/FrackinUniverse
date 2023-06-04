function isn_getCurrentPowerInput(divide)
	---sb.logInfo("POWER INPUT DEBUG aka PID")
	---sb.logInfo("called by " .. world.entityName(entity.id()))
	local totalInput = 0
	local iterator = 0
	local connectedDevices

	local nodecount = object.inputNodeCount()
	---sb.logInfo("PID: nodecount is " .. nodecount)

	while iterator < nodecount do
		---sb.logInfo("PID: Iteration " .. iterator)
		if object.getInputNodeLevel(iterator) == true then
			connectedDevices = object.getInputNodeIds(iterator)
			for id in pairs(connectedDevices) do
				---sb.logInfo("PID: id is " .. id)
				---sb.logInfo("PID: powerLevel is " .. connectedDevices[id])
				---sb.logInfo("PID: ID check resolves to " .. world.entityName(id))
				if world.callScriptedEntity(id,"isn_canSupplyPower") == true then
					local output = world.callScriptedEntity(id,"isn_getCurrentPowerOutput",divide)
					---sb.logInfo("PID: Power supplier detected with output of " .. output)
					if output ~= nil then totalInput = totalInput + output end
				else
					---sb.logInfo("PID: Detected non power-supplying device")
				end
			end
		end
		---sb.logInfo("PID: total input now at " .. totalInput)
		iterator = iterator + 1
	end

	---sb.logInfo("GENERAL POWER INPUT DEBUG END")
	return totalInput
end

function isn_hasRequiredPower()
	local power = isn_getCurrentPowerInput(true)
	local requirement = config.getParameter("isn_requiredPower")
	if power == nil then return false end
	if requirement == nil then return true end

	if power >= requirement then return true
	else return false end
end

function isn_canSupplyPower()
	if config.getParameter("isn_powerSupplier") == true then return true
	else return false end
end

function isn_canReceivePower()
	if config.getParameter("isn_powerReceiver") == true then return true
	else return false end
end

function isn_doesNotConsumePower()
	if config.getParameter("isn_freePower") == true then return true
	else return false end
end

function isn_checkValidOutput()
	local connectedDevices = object.getOutputNodeIds(0)
	if not connectedDevices then return false end
	for id in pairs(connectedDevices) do
		if world.callScriptedEntity(id,"isn_canReceivePower") == false then return false end
	end
	return true
end

function isn_countPowerDevicesConnectedOnOutboundNode(node)
	---sb.logInfo("POWER DEVICE COUNT DEBUG BEGIN aka PDCDB")
	if node == nil then return 0 end
	local devicecount = 0
	local devicelist = object.getOutputNodeIds(node)
	if devicelist == nil then return 0 end
	---sb.logInfo("PDCDB: iterating detected devices")
	for id in pairs(devicelist) do
		---sb.logInfo("PDCDB: id is " .. id)
		---sb.logInfo("PDCDB: powerLevel is " .. devicelist[id])
		---local devicecheck = world.entityName(id)
		---if not devicecheck then
			---sb.logInfo("PDCDB: id resolves to nil")
		---else
			---sb.logInfo("PDCDB: id resolves to " .. devicecheck)
		---end
		if world.callScriptedEntity(id,"isn_canReceivePower") == true then
			if world.callScriptedEntity(id,"isn_doesNotConsumePower") == false then
				---sb.logInfo("PDCDB: power-consuming device detected and added to count")
				devicecount = devicecount + 1
			end
		end
	end
	---sb.logInfo("POWER DEVICE COUNT DEBUG END")
	return devicecount
end
