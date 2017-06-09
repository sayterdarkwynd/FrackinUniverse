require "/objects/power/isn_sharedpowerscripts.lua"

function init()
	if storage.currentstoredpower == nil then storage.currentstoredpower = 0 end
	if storage.excessCurrent == nil then storage.excessCurrent = false end
	
	isn_powerInit()
end

function update(dt)
	if not storage.init then
		storage.currentstoredpower = world.getObjectParameter(entity.id(), 'isnStoredPower') or 0
		storage.init = true
	end

	storage.recentlyDischarged = false

	if storage.currentstoredpower < storage.voltage then
		animator.setAnimationState("meter", "d")
	else
		local powerlevel = math.floor(isn_numericRange(isn_getXPercentageOfY(storage.currentstoredpower,storage.powercapacity)/10,0,10))
		animator.setAnimationState("meter", tostring(powerlevel))
	end

	local powerinput = isn_getCurrentPowerInput()
	if powerinput and powerinput >= 1 then
		storage.currentstoredpower = storage.currentstoredpower + powerinput
	end
	local poweroutput, batteries = isn_sumPowerActiveDevicesConnectedOnOutboundNode(storage.powerInNode)
	storage.excessCurrent = poweroutput > storage.voltage
	animator.setAnimationState("status", storage.excessCurrent and "error" or "on")
	if (batteries > 0 or poweroutput > 0) and storage.currentstoredpower > 0 and not storage.excessCurrent then
		storage.recentlyDischarged = poweroutput + batteries * isn_getCurrentPowerOutput(storage.powerInNode)
		storage.currentstoredpower = storage.currentstoredpower - storage.recentlyDischarged
	end

	storage.currentstoredpower = math.min(storage.currentstoredpower, storage.powercapacity)
	object.setConfigParameter('description', isn_makeBatteryDescription())
end

function isn_getCurrentPowerStorage()
	return isn_getXPercentageOfY(storage.currentstoredpower,storage.powercapacity)
end

function isn_recentlyDischarged()
	return storage.recentlyDischarged
end

function isn_hasStoredPower()
	return storage.currentstoredpower > 0
end

function isn_getCurrentPowerOutput()
	if not isn_hasStoredPower() or storage.excessCurrent then return 0 end
	return storage.voltage

end

function onNodeConnectionChange()
	nodeStuff()
end
function onInputNodeChange()
	nodeStuff()
end

function nodeStuff()
	if storage.powerOutNode then
		object.setOutputNodeLevel(storage.powerOutNode, isn_getCurrentPowerOutput()>0)
	end
end

function die()
	if storage.currentstoredpower >= storage.voltage then
		local charge = isn_getCurrentPowerStorage()
		local iConf = root.itemConfig(object.name())
		local newObject = { isnStoredPower = storage.currentstoredpower }

		if iConf and iConf.config then
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

			newObject.description = isn_makeBatteryDescription(iConf.config.description or '', charge)
		end

		world.spawnItem(object.name(), entity.position(), 1, newObject)
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
	if charge == 0 then return desc end

	if charge < 0.5 then
		charge = '< 0.5'
	else
		charge = math.floor (charge * 2) / 2
	end

	return desc .. (desc ~= '' and "\n" or '') .. "^yellow;Stored charge: " .. charge .. '%'
end
