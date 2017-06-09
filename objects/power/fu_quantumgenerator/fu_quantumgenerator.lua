require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0
function init()
	transferUtil.init()
    object.setInteractive(true)
    object.setSoundEffectEnabled(false)
   
    storage.currentpowerprod = storage.currentpowerprod or 0
    storage.powerprodmod = storage.powerprodmod or 0
    storage.fueledticks = storage.fueledticks or 0
    storage.decayrate = storage.decayrate or 5
    if storage.active == nil then storage.active = true end
    if storage.batteryHold == nil then storage.batteryHold = false end
end
 
function onInputNodeChange(args)
    storage.active =  not object.isInputNodeConnected(0) or (object.isInputNodeConnected(0) and object.getInputNodeLevel(0))
end
 
function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	local devices = isn_getAllDevicesConnectedOnNode(0,"output")
	-- sb.logInfo("devices found: %s", devices)
	local fullBattery = false
	local spendingPower = false
	for key,value in pairs(devices) do
		-- sb.logInfo("Checking device %s", value)
		if world.callScriptedEntity(value, "isn_isBattery") then
			local currentBatteryStorage = world.callScriptedEntity(value, "isn_getCurrentPowerStorage")
			if currentBatteryStorage > 99 then
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
 
    if storage.currentpowerprod > 10 and storage.active and not storage.batteryHold then
        animator.setAnimationState("screen", "slow")
        animator.setAnimationState("fans", "slow")
        local lightRGB = config.getParameter("lightColor",{126,206,255})
        local brightness = math.min(0.75,0.75*(storage.currentpowerprod/90))
        lightRGB[1] = math.floor(lightRGB[1]*0.25 + lightRGB[1]*brightness)
        lightRGB[2] = math.floor(lightRGB[2]*0.25 + lightRGB[2]*brightness)
        lightRGB[3] = math.floor(lightRGB[3]*0.25 + lightRGB[3]*brightness)
        object.setLightColor(lightRGB)
        object.setSoundEffectEnabled(true)
    else
        animator.setAnimationState("screen", "off")
        animator.setAnimationState("fans", "off")
        object.setLightColor({0, 0, 0, 0})
        object.setSoundEffectEnabled(false)
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
                    storage.fueledticks = value / 3 + math.random(20)
                    storage.powerprodmod = value
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
    if storage.currentpowerprod > 70 then powercount = 20 + storage.powerprodmod
    elseif storage.currentpowerprod > 50 then powercount = 16 + storage.powerprodmod
    elseif storage.currentpowerprod > 30 then powercount = 12 + storage.powerprodmod
    elseif storage.currentpowerprod > 20 then powercount = 9 + storage.powerprodmod
    elseif storage.currentpowerprod > 5 then powercount = 5 + storage.powerprodmod
    end
    ---sb.logInfo("TGCPOD: Powercount is" .. powercount)
   
    ---sb.logInfo("THERMAL GENERATOR CURRENT POWER OUTPUT DEBUG END")
    return divide and (powercount/divisor) or powercount
end
 
function onNodeConnectionChange()
    object.setOutputNodeLevel(0, isn_checkValidOutput())
end