function init(virtual)
	if virtual == true then return end
	entity.setInteractive(true)
	entity.setSoundEffectEnabled(false)
	
	if storage.currentpowerprod == nil then storage.currentpowerprod = 0 end
	if storage.fueledticks == nil then storage.fueledticks = 0 end
	if storage.decayrate == nil then storage.decayrate = 5 end
	if storage.active == nil then storage.active = true end
end

function onInboundNodeChange(args)
	if entity.isInboundNodeConnected(0) then
		if entity.getInboundNodeLevel(0) == true then storage.active = true
		else storage.active = false
		end
	else storage.active = true
	end
end

function update(dt)
	-- check current power production and set the animation state accordingly
	if storage.currentpowerprod > 90 then
		animator.setAnimationState("screen", "fast")
		entity.setLightColor(entity.configParameter("lightColor", {166, 166, 166}))
	elseif storage.currentpowerprod > 50 then
		animator.setAnimationState("screen", "med")
		animator.setAnimationState("fans", "fast")
		entity.setLightColor(entity.configParameter("lightColor", {100, 100, 100}))
		entity.setSoundEffectEnabled(true)
	elseif storage.currentpowerprod > 10 then
		animator.setAnimationState("screen", "slow")
		animator.setAnimationState("fans", "slow")
		entity.setLightColor(entity.configParameter("lightColor", {50, 50, 50}))
		entity.setSoundEffectEnabled(false)
	else
		animator.setAnimationState("screen", "off")
		animator.setAnimationState("fans", "off")
		entity.setLightColor({0, 0, 0, 0})	
	end

	if storage.fueledticks > 0 then -- if we're currently fueled up
		-- Decrement our current fuel by one
		storage.fueledticks = storage.fueledticks - 1
		-- Increase power but cap it at a 0-100 range
		storage.currentpowerprod = isn_numericRange((storage.currentpowerprod + storage.decayrate),0,100)
	else -- oh no we've got no fuel
		-- if the generator isn't active don't bother trying to refuel
		
		if storage.active == true then
			-- try to get some fuel
			local contents = world.containerItems(entity.id())
			if contents[1] == nil then
				-- if there's nothing in storage just skip straight to cutting power
				storage.currentpowerprod = isn_numericRange((storage.currentpowerprod - storage.decayrate),0,100)
				return
			end
			
			for key, value in pairs(entity.configParameter("acceptablefuel")) do
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
	---world.logInfo("THERMAL GENERATOR CURRENT POWER OUTPUT DEBUG aka TGCPOD")
	local divisor = isn_countPowerDevicesConnectedOnOutboundNode(0)
	---world.logInfo("TGCPOD: Divisor is " .. divisor)
	if divisor < 1 then divisor = 1 end
	
	local powercount = 0
	if storage.currentpowerprod > 90 then powercount = 10
	elseif storage.currentpowerprod > 70 then powercount = 8
	elseif storage.currentpowerprod > 50 then powercount = 6
	elseif storage.currentpowerprod > 30 then powercount = 4
	elseif storage.currentpowerprod > 10 then powercount = 2	
	else powercount = 0 end
	---world.logInfo("TGCPOD: Powercount is" .. powercount)
	
	---world.logInfo("THERMAL GENERATOR CURRENT POWER OUTPUT DEBUG END")
	if divide == true then return powercount / divisor
	else return powercount end
end

function onNodeConnectionChange()
	if isn_checkValidOutput() == true then entity.setOutboundNodeLevel(0, true)
	else entity.setOutboundNodeLevel(0, false) end
end