function init()
	

	if storage.currentstoredpower == nil then storage.currentstoredpower = 0 end
	if storage.powercapacity == nil then storage.powercapacity = config.getParameter("isn_batteryCapacity") end
	if storage.voltage == nil then storage.voltage = config.getParameter("isn_batteryVoltage") end
	if storage.active == nil then storage.active = onInputNodeChange() end
	if storage.excessCurrent == nil then storage.excessCurrent = false end
end

function update(dt)
	if not storage.init then
		-- sb.logInfo ('battery ' .. entity.id() .. ' stored power = ' .. (world.getObjectParameter(entity.id(), 'isnStoredPower') or 'nil'))
		storage.currentstoredpower = world.getObjectParameter(entity.id(), 'isnStoredPower') or 0
		storage.init = true
	end

	storage.recentlyDischarged = false

	if storage.currentstoredpower < storage.voltage then
		-- less than storage.voltage in store; considered discharged
		animator.setAnimationState("meter", "d")
	else	-- not discharged
		local powerlevel = isn_getXPercentageOfY(storage.currentstoredpower,storage.powercapacity)
		if powerlevel ~= 0 then powerlevel = powerlevel / 10 end	-- Q:Why a separate statement? A:if function returns nil, /10 will error. -r
		powerlevel = isn_numericRange(powerlevel,0,10)
		animator.setAnimationState("meter", tostring(math.floor(powerlevel)))
	end

	local powerinput = isn_getCurrentPowerInput(false)  -- set this to (true) to enable batteries losing power (divisor)
	if powerinput and powerinput >= 1 then
		storage.currentstoredpower = storage.currentstoredpower + powerinput
		-- sb.logInfo(string.format("Storing %.2fu, now at %.2fu", powerinput, storage.currentstoredpower))
	end

	if storage.active then
		-- drain power according to attached devices; max drain is storage.voltage
		local poweroutput, batteries = isn_sumPowerActiveDevicesConnectedOnOutboundNode(0)
		storage.excessCurrent = poweroutput > storage.voltage
		animator.setAnimationState("status", storage.excessCurrent and "error" or "on")
		if (batteries > 0 or poweroutput > 0) and storage.currentstoredpower > 0 and not storage.excessCurrent then
			storage.recentlyDischarged = poweroutput + batteries * isn_getCurrentPowerOutput(true)
			storage.currentstoredpower = storage.currentstoredpower - storage.recentlyDischarged
			-- sb.logInfo(string.format("Draining %.2fu, now at %.2fu", poweroutput, storage.currentstoredpower))
		end
	else
		animator.setAnimationState("status", "off")
	end

	storage.currentstoredpower = math.min(storage.currentstoredpower, storage.powercapacity)
	--object.setConfigParameter('isnStoredPower', storage.currentstoredpower)
	object.setConfigParameter('description', isn_makeBatteryDescription())
end

function isn_getCurrentPowerStorage()
	return isn_getXPercentageOfY(storage.currentstoredpower,storage.powercapacity)
end

function isn_recentlyDischarged()
	return storage.recentlyDischarged
end

function isn_hasStoredPower()
	if not storage.active then return false end  -- This might be pointless. Need to think about it. -r
	return storage.currentstoredpower > 0
end

function isn_getCurrentPowerOutput(divide)
	if not isn_hasStoredPower() or storage.excessCurrent then return 0 end

	local divisor = isn_countPowerDevicesConnectedOnOutboundNode(0)

	-- if divisor < 1 then return 0 end
	if divide and divisor > 0 then return storage.voltage / divisor
	else return storage.voltage end
end

function onNodeConnectionChange()
    if isn_checkValidOutput() then
        storage.active = true;
        object.setOutputNodeLevel(0, true);
    else
        storage.active = false;
        object.setOutputNodeLevel(0, false);
    end
end

function onInputNodeChange(args)
	-- If either input is connected and at logic low, go inactive. This allows switches to work.
	storage.active = (not object.isInputNodeConnected(0) or object.getInputNodeLevel(0)) and (not object.isInputNodeConnected(1) or object.getInputNodeLevel(1))
	object.setOutputNodeLevel(0, storage.active)
end

function die()
	if storage.currentstoredpower >= storage.voltage then
		local charge = isn_getCurrentPowerStorage()
		local iConf = root.itemConfig(object.name())
		local newObject = { isnStoredPower = storage.currentstoredpower }

		if iConf and iConf.config then
			-- set the border colour according to the charge level (red → yellow → green)
			if iConf.config.inventoryIcon then
				local colour

				if     charge <  25 then colour = 'FF0000'
				elseif charge <  50 then colour = 'FF8000'
				elseif charge <  75 then colour = 'FFFF00'
				elseif charge < 100 then colour = '80FF00'
				else                     colour = '00FF00'
				end
				newObject.inventoryIcon = iConf.config.inventoryIcon .. '?border=1;' .. colour .. '?fade=' .. colour .. 'FF;0.1'
			end

			-- append the stored charge %age (rounded to 0.5) to the description
			newObject.description = isn_makeBatteryDescription(iConf.config.description or '', charge)
		end

		world.spawnItem(object.name(), entity.position(), 1, newObject)
		-- object.smash(true)
	else
		world.spawnItem(object.name(), entity.position())
	end
end

function isn_makeBatteryDescription(desc, charge)
	if desc == nil then
		desc = root.itemConfig(object.name())
		desc = desc and desc.config and desc.config.description or ''
	end
	if charge == nil then charge = isn_getCurrentPowerStorage() end

	-- bat flattery
	if charge == 0 then return desc end

	-- round down to multiple of 0.5 (special case if < 0.5)
	if charge < 0.5 then
		charge = '< 0.5'
	else
		charge = math.floor (charge * 2) / 2
	end

	-- append charge state to default description; ensure that it's on a line of its own
	return desc .. (desc ~= '' and "\n" or '') .. "^yellow;Stored charge: " .. charge .. '%'
end
