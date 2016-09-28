function isn_getCurrentPowerInput(divide)
	--- If this is not a battery and a passthrough is connected, there must only be one and no PSUs except those connected via it
	--- If that condition is not met, this function returns nil
	-- sb.logInfo("POWER INPUT DEBUG aka PID")
	-- sb.logInfo("called by " .. world.entityName(entity.id()))
	local totalInput = 0
	local connectedDevices
	local output = 0
	local hasPSU = false
	local hasPassthrough = false
	local isBattery = isn_isBattery()
	
	-- sb.logInfo("PID: nodecount is " .. object.inputNodeCount())
	
	for iterator = 0, object.inputNodeCount() - 1 do
		-- sb.logInfo("PID: Iteration " .. iterator)
		if object.getInputNodeLevel(iterator) then
			connectedDevices = isn_getAllDevicesConnectedOnNode(iterator,"input")
			for key, value in pairs (connectedDevices) do
				-- sb.logInfo("PID: key is " .. key)
				-- sb.logInfo("PID: value is " .. value)
				-- sb.logInfo("PID: value ID check resolves to " .. world.entityName(value))
				if world.callScriptedEntity(value,"isn_canSupplyPower") then
					if not isBattery then
						local isPassthrough = world.callScriptedEntity(value,"isn_isPowerPassthrough")
						if isPassthrough then
							if hasPSU or hasPassthrough then return nil end --ERROR (passthrough; already found a PSU or passthrough)
							hasPassthrough = true
						else
							if hasPassthrough then return nil end --ERROR (PSU; already found a passthrough)
							hasPSU = true
						end
					end

					output = world.callScriptedEntity(value,"isn_getCurrentPowerOutput",divide)
					-- sb.logInfo("PID: Power supplier detected with output of " .. output)
					if output ~= nil then totalInput = totalInput + output end
				else
					-- sb.logInfo("PID: Detected non power-supplying device")
				end
			end
		end
		-- sb.logInfo("PID: total input now at " .. totalInput)
	end
	
	-- sb.logInfo("GENERAL POWER INPUT DEBUG END")
	return totalInput
end

function isn_countCurrentPowerInputs()
	--- Same rule as for isn_getCurrentPowerInput()
	local connectedDevices
	local psus = 0
	local totalInput = 0
	local hasPSU = false
	local hasPassthrough = false

	for iterator = 0, object.inputNodeCount() - 1 do
		if object.getInputNodeLevel(iterator) then
			connectedDevices = isn_getAllDevicesConnectedOnNode(iterator,"input")
			for key, value in pairs (connectedDevices) do
				if world.callScriptedEntity(value,"isn_canSupplyPower") then
					local isPassthrough = world.callScriptedEntity(value,"isn_isPowerPassthrough")
					if not isBattery then
						if isPassthrough then
							if hasPSU or hasPassthrough then return nil end --ERROR (passthrough; already found a PSU or passthrough)
							hasPassthrough = true
						else
							if hasPassthrough then return nil end --ERROR (PSU; already found a passthrough)
							hasPSU = true
						end
					end
					if isPassthrough or world.callScriptedEntity(value, "isn_hasStoredPower") then
						psus = psus + 1
					end
				end
			end
		end
	end
	return psus
end

function isn_hasRequiredPower()
	local power = isn_getCurrentPowerInput(true)
	local requirement = config.getParameter("isn_requiredPower")
	if power == nil then return false end
	if requirement == nil then return true end
	
	if power >= requirement then return true
	else return false end
end

function isn_requiredPowerValue(persupply)
	local req

	if config.getParameter("isn_powerPassthrough") then
		-- It's a conduit, or a similar device. Check what downstream says.
		req = isn_sumPowerActiveDevicesConnectedOnOutboundNode(0)
	else
		req = config.getParameter("isn_requiredPower")
	end
	if req == nil then return nil end

	-- If requested, get the number of connected active power supplies and split the power requirement equally across them
	-- (mainly because we don't know which PSU is calling us)
	local psus = 0
	if persupply then psus = isn_countCurrentPowerInputs() end
	if psus == nil then return nil end

	return psus > 0 and req / psus or req
end

function isn_canSupplyPower()
	if config.getParameter("isn_powerSupplier") then return true
	else return false end
end

function isn_canRecievePower()
	if config.getParameter("isn_powerReciever") then return true
	else return false end
end

function isn_doesNotConsumePower()
	if config.getParameter("isn_freePower") then return true
	else return false end
end

function isn_isPowerPassthrough()
	if config.getParameter("isn_powerPassthrough") then return true
	else return false end
end

function isn_isBattery()
	local capacity = config.getParameter("isn_batteryCapacity")
	if capacity ~= nil and capacity > 0 then return true
	else return false end
end

function isn_areActivePowerDevicesConnectedOnOutboundNode(node)
	if node == nil then return false end
	local devicelist = isn_getAllDevicesConnectedOnNode(node,"output")
	if devicelist == nil then return false end
	for key, value in pairs(devicelist) do
		if world.callScriptedEntity(value,"isn_canRecievePower") then
			if not world.callScriptedEntity(value,"isn_doesNotConsumePower") then
				if world.callScriptedEntity(value,"isn_activeConsumption") then
					return true
				end
			end
		end
	end
	return false
end

function isn_activeConsumption()
	if config.getParameter("isn_powerPassthrough") then -- It's a conduit (or similar device), better check what downstream says -r
		for iterator = 0, object.outputNodeCount() - 1 do
			if isn_areActivePowerDevicesConnectedOnOutboundNode(iterator) then return true end
		end
		return false
	end
	return storage.activeConsumption == nil or storage.activeConsumption		-- shim in place for uncorrected stations
end

function isn_checkValidOutput()
	local connectedDevices = isn_getAllDevicesConnectedOnNode(0,"output")
	if connectedDevices == nil then return false end
	for key, value in pairs(connectedDevices) do
		if not world.callScriptedEntity(value,"isn_canRecievePower") then return false end
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
		if world.callScriptedEntity(value,"isn_canRecievePower") then
			if not world.callScriptedEntity(value,"isn_doesNotConsumePower") then
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
	local batteries = 0
	local devicelist = isn_getAllDevicesConnectedOnNode(node,"output")
	if devicelist == nil then return 0 end
	for key, value in pairs(devicelist) do
		if world.callScriptedEntity(value,"isn_canRecievePower") then
			if not world.callScriptedEntity(value,"isn_doesNotConsumePower") then
				if world.callScriptedEntity(value,"isn_isBattery") == true then
					if world.callScriptedEntity(value, "isn_recentlyDischarged") then batteries = batteries + 1 end
				elseif world.callScriptedEntity(value,"isn_activeConsumption") then
					-- allow for the consumer's power requirement being spread across several supplies
					local required = world.callScriptedEntity(value,"isn_requiredPowerValue", true)
					if required ~= nil then voltagecount = voltagecount + required end
					-- sb.logInfo(entity.id() .. ": Found a consumer, " .. value .. ", requiring " .. (required or 'nil') .. "; total increased to " .. voltagecount)
				end
			end
		end
	end
	return voltagecount, batteries
end
