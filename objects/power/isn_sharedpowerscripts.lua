function isn_getCurrentPowerInput(divide)
	-- sb.logInfo("POWER INPUT DEBUG aka PID")
	-- sb.logInfo("called by " .. world.entityName(entity.id()))
	local totalInput = 0
	local iterator = 0
	local connectedDevices
	local output = 0
	
	local nodecount = object.inputNodeCount() 
	-- sb.logInfo("PID: nodecount is " .. nodecount)
	
	while iterator < nodecount do
		-- sb.logInfo("PID: Iteration " .. iterator)
		if object.getInputNodeLevel(iterator) == true then
			connectedDevices = isn_getAllDevicesConnectedOnNode(iterator,"input")
			for key, value in pairs (connectedDevices) do
				-- sb.logInfo("PID: key is " .. key)
				-- sb.logInfo("PID: value is " .. value)
				-- sb.logInfo("PID: value ID check resolves to " .. world.entityName(value))
				if world.callScriptedEntity(value,"isn_canSupplyPower") == true then
					output = world.callScriptedEntity(value,"isn_getCurrentPowerOutput",divide)
					-- sb.logInfo("PID: Power supplier detected with output of " .. output)
					if output ~= nil then totalInput = totalInput + output end
				else
					-- sb.logInfo("PID: Detected non power-supplying device")
				end
			end
		end
		-- sb.logInfo("PID: total input now at " .. totalInput)
		iterator = iterator + 1
	end
	
	-- sb.logInfo("GENERAL POWER INPUT DEBUG END")
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

function isn_requiredPowerValue()
	return config.getParameter("isn_requiredPower")
end

function isn_canSupplyPower()
	if config.getParameter("isn_powerSupplier") == true then return true
	else return false end
end

function isn_canRecievePower()
	if config.getParameter("isn_powerReciever") == true then return true
	else return false end
end

function isn_doesNotConsumePower()
	if config.getParameter("isn_freePower") == true then return true
	else return false end
end

function isn_isBattery()
	local capacity = config.getParameter("isn_batteryCapacity")
	if capacity ~= nil and capacity > 0 then return true
	else return false end
end

function isn_activeConsumption()
	return storage.activeConsumption == nil or storage.activeConsumption		-- shim in place for uncorrected stations
end

function isn_checkValidOutput()
	local connectedDevices = isn_getAllDevicesConnectedOnNode(0,"output")
	if connectedDevices == nil then return false end
	for key, value in pairs(connectedDevices) do
		if world.callScriptedEntity(value,"isn_canRecievePower") == false then return false end
	end
	return true
end

function isn_countPowerDevicesConnectedOnOutboundNode(node)
	---sb.logInfo("POWER DEVICE COUNT DEBUG BEGIN aka PDCDB")
	if node == nil then return 0 end
	local devicecount = 0
	local devicelist = isn_getAllDevicesConnectedOnNode(node,"output")
	if devicelist == nil then return 0 end
	---sb.logInfo("PDCDB: iterating detected devices")
	for key, value in pairs(devicelist) do
		---sb.logInfo("PDCDB: key is " .. key)
		---sb.logInfo("PDCDB: value is " .. value)
		---local devicecheck = world.entityName(value)
		---if devicecheck == nil then
			---sb.logInfo("PDCDB: value resolves to nil")
		---else
			---sb.logInfo("PDCDB: value resolves to " .. devicecheck)
		---end
		if world.callScriptedEntity(value,"isn_canRecievePower") == true then
			if world.callScriptedEntity(value,"isn_doesNotConsumePower") == false then
				---sb.logInfo("PDCDB: power-consuming device detected and added to count")
				devicecount = devicecount + 1
			end
		end
	end
	---sb.logInfo("POWER DEVICE COUNT DEBUG END")
	return devicecount
end

function isn_sumPowerActiveDevicesConnectedOnOutboundNode(node)
	if node == nil then return 0 end
	local voltagecount = 0
	local devicelist = isn_getAllDevicesConnectedOnNode(node,"output")
	if devicelist == nil then return 0 end
	for key, value in pairs(devicelist) do
		if world.callScriptedEntity(value,"isn_canRecievePower") == true then
			if world.callScriptedEntity(value,"isn_doesNotConsumePower") == false then
				if world.callScriptedEntity(value,"isn_activeConsumption") == true then
					voltagecount = voltagecount + world.callScriptedEntity(value,"isn_requiredPowerValue")
					-- sb.logInfo("Found a consumer, " .. value .. ", total increased to " .. voltagecount)
				end
			end
		end
	end
	return voltagecount
end
