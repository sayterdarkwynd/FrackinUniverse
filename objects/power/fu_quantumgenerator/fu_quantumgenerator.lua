function init(virtual)
	if virtual == true then return end
	object.setInteractive(true)
	object.setSoundEffectEnabled(false)
	
	if storage.currentpowerprod == nil then storage.currentpowerprod = 0 end
	if storage.fueledticks == nil then storage.fueledticks = 0 end
	if storage.decayrate == nil then storage.decayrate = 5 end
	if storage.active == nil then storage.active = true end	
	if storage.batteryHold == nil then storage.batteryHold = false end
end

function onInputNodeChange(args)
	if object.isInputNodeConnected(0) then
		if object.getInputNodeLevel(0) == true then storage.active = true
		else storage.active = false
		end
	else storage.active = true
	end
end

function update(dt)

	local devices = isn_getAllDevicesConnectedOnNode(0,"output")
	-- sb.logInfo("devices found: %s", devices)
	local fullBattery = false
	local spendingPower = false
	for key,value in pairs(devices) do
		-- sb.logInfo("Checking device %s", value)
		if world.callScriptedEntity(value, "isn_isBattery") then
			local currentBatteryStorage = world.callScriptedEntity(value, "isn_getCurrentPowerStorage")
			if currentBatteryStorage > 98 then
				fullBattery = true
			else
				if storage.batteryHold and currentBatteryStorage > 90 then
					fullBattery = true
				else
					spendingPower = true
				end
			end
		else
			if not world.callScriptedEntity(value, "isn_doesNotConsumePower") then
				spendingPower = true
			end
		end
	end
	if fullBattery and not spendingPower then
		storage.batteryHold = true
		-- sb.logInfo("Battery full and no other consumers connected, shutting down")
	else
		storage.batteryHold = false
	end

	-- check current power production and set the animation state accordingly
	if storage.currentpowerprod > 90 and storage.active and not storage.batteryHold then
		animator.setAnimationState("screen", "slow")
        object.setLightColor(config.getParameter("lightColor", {126, 206, 255}))
        object.setSoundEffectEnabled(true)
	elseif storage.currentpowerprod > 50 and storage.active and not storage.batteryHold then
		animator.setAnimationState("screen", "slow")
		animator.setAnimationState("fans", "slow")
        object.setLightColor(config.getParameter("lightColor", {70, 126, 161}))		
		object.setSoundEffectEnabled(true)
	elseif storage.currentpowerprod > 10 and storage.active and not storage.batteryHold then
		animator.setAnimationState("screen", "slow")
		animator.setAnimationState("fans", "slow")
        object.setLightColor(config.getParameter("lightColor", {35, 79, 87}))
		object.setSoundEffectEnabled(true)
	else
		animator.setAnimationState("screen", "off")
		animator.setAnimationState("fans", "off")
		object.setSoundEffectEnabled(false)
        object.setLightColor({0, 0, 0, 0})		
	end

	if not storage.active or storage.batteryHold then
		return
	end

	if storage.fueledticks > 0 then -- if we're currently fueled up
		  storage.fueledticks = storage.fueledticks - 1
		-- Increase power but cap it at a 0-100 range
		storage.currentpowerprod = isn_numericRange((storage.currentpowerprod + storage.decayrate),0,100)
	else -- oh no we've got no fuel
		-- if the generator isn't active don't bother trying to refuel
		if storage.active then
			-- try to get some fuel
			local contents = world.containerItems(entity.id())
			if contents[1] == nil then
				-- if there's nothing in storage just skip straight to cutting power
				storage.currentpowerprod = isn_numericRange((storage.currentpowerprod - storage.decayrate),0,100)
				return
			end
			
			for key, value in pairs(config.getParameter("acceptablefuel")) do
				-- go through our fuel table and see if the contents of the fuel slot match
				if key == contents[1].name then -- found it!
					storage.fueledticks = value
					world.containerConsume(entity.id(), {name = contents[1].name, count = 1, data={}})
					return -- end it here since we want to start again with the new fuel
				end
			end
		end
		-- since the loop ends this update if it finds fuel, if we've reached this point
		-- it means we didn't find any fuel so now we decrease power gradually
		storage.currentpowerprod = isn_numericRange((storage.currentpowerprod - storage.decayrate),0,100)
	end
end

function isn_getCurrentPowerOutput(divide)

	if storage.batteryHold or not storage.active then return 0 end

	---sb.logInfo("THERMAL GENERATOR CURRENT POWER OUTPUT DEBUG aka TGCPOD")
	local divisor = isn_countPowerDevicesConnectedOnOutboundNode(0)
	---sb.logInfo("TGCPOD: Divisor is " .. divisor)
	if divisor < 1 then divisor = 1 end
	
	local powercount = 0
	if storage.currentpowerprod > 90 then powercount = 40
	elseif storage.currentpowerprod > 70 then powercount = 32
	elseif storage.currentpowerprod > 50 then powercount = 24
	elseif storage.currentpowerprod > 30 then powercount = 18
	elseif storage.currentpowerprod > 10 then powercount = 9
	else powercount = 0 end
	---sb.logInfo("TGCPOD: Powercount is" .. powercount)
	
	---sb.logInfo("THERMAL GENERATOR CURRENT POWER OUTPUT DEBUG END")
	if divide == true then return powercount / divisor
	else return powercount end
end

function onNodeConnectionChange()
	if isn_checkValidOutput() == true then object.setOutputNodeLevel(0, true)
	else object.setOutputNodeLevel(0, false) end
end