require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0

function init()
	transferUtil.init()
	wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	tritiumstack = world.containerSwapItems(entity.id(),{name = "tritium", count = 1, data={}},5)
        storage.critChance = 50
	
	object.setInteractive(true)
	
	if storage.radiation == nil then storage.radiation = 0 end
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

	if storage.radiation >= 100 then
		animator.setAnimationState("hazard", "danger")
	elseif storage.radiation >= 60 then
		animator.setAnimationState("hazard", "warn")
	elseif storage.radiation >= 1 then
		animator.setAnimationState("hazard", "safe")
	else 
		animator.setAnimationState("hazard", "off")
	end

	if not storage.active or storage.batteryHold then
		storage.radiation = storage.radiation - 5
		storage.radiation = isn_numericRange(storage.radiation,0,120)
		animator.setAnimationState("screen", "off")
		return
	end
	
	if isn_slotDecayCheck(0,1) == true then isn_doSlotDecay(0) end
	if isn_slotDecayCheck(1,1) == true then isn_doSlotDecay(1) end
	if isn_slotDecayCheck(2,1) == true then isn_doSlotDecay(2) end
	if isn_slotDecayCheck(3,1) == true then isn_doSlotDecay(3) end
	
	local power = isn_getCurrentPowerOutput(false)
	if power > 11 then
	  animator.setAnimationState("screen", "on")
	elseif power >= 6 then
	  animator.setAnimationState("screen", "med")
	elseif power >= 1 then 
	  animator.setAnimationState("screen", "slow")
	elseif power <= 0 then
	  animator.setAnimationState("screen", "off")
	end
	
	local rads = -4
	rads = rads + power
	if rads > 0 then rads = rads * 2 end
	local waste =  world.containerAvailable(entity.id(),"toxicwaste")
	local tritium =  world.containerAvailable(entity.id(),"tritium")
	if waste >= 75 then
		rads = rads + 5
	end
	storage.radiation = storage.radiation + rads
	storage.radiation = isn_numericRange(storage.radiation,0,120)

	local myLocation = entity.position()
	world.debugText("R:" .. storage.radiation, {myLocation[1]-1, myLocation[2]-2}, "red"); 

	if storage.radiation >= 50 then
		isn_projectileAllInRange("isn_fissionrads",4)
	end
	
	if storage.radiation >= 80 then
		isn_projectileAllInRange("isn_fissionrads",8)
	end

	if storage.radiation >= 100 then
		isn_projectileAllInRange("isn_fissionrads",12)
	end

	if storage.radiation >= 120 then
		isn_projectileAllInRange("isn_fissionrads",16)
	end
end

function isn_powerSlotCheck(slotnum)
	local contents = world.containerItems(entity.id())
	local slotContent = world.containerItemAt(entity.id(),slotnum)
	
	if slotContent == nil then return 0 end
	if slotContent.name == "biofuelcannister" then return 4
	elseif slotContent.name == "biofuelcannisteradv" then return 4
	elseif slotContent.name == "biofuelcannistermax" then return 5
	elseif slotContent.name == "uraniumrod" then return 6
	elseif slotContent.name == "neptuniumrod" then return 6
	elseif slotContent.name == "tritium" then return 6	
	elseif slotContent.name == "deuterium" then return 7
	elseif slotContent.name == "thoriumrod" then return 7	
	elseif slotContent.name == "enricheduranium" then return 8
	elseif slotContent.name == "plutoniumrod" then return 10
	elseif slotContent.name == "enrichedplutonium" then return 12
	elseif slotContent.name == "solariumstar" then return 15
	elseif slotContent.name == "ultronium" then return 20
	else return 0 end
end

function isn_slotDecayCheck(slot, chance)
	local contents = world.containerItems(entity.id())
	local slotContent = world.containerItemAt(entity.id(),slot)
	local myLocation = entity.position()

	world.debugText("CHECK",{myLocation[1]-1,myLocation[2]-3.5},"cyan")

	if slotContent == nil then return false end

	if slotContent.name == "biofuelcannister" or slotContent.name == "biofuelcannisteradv" or slotContent.name == "biofuelcannistermax" then
		if math.random(1,60) <= chance then world.debugText("DECAY",{myLocation[1]+2,myLocation[2]-3.5},"cyan"); return true end
	end
	
	if slotContent.name == "tritium" or slotContent.name == "deuterium" or slotContent.name == "uraniumrod" or slotContent.name == "plutoniumrod" or slotContent.name == "neptuniumrod" then
		if math.random(1,80) <= chance then world.debugText("DECAY",{myLocation[1]+2,myLocation[2]-3.5},"cyan"); return true end
	end	
	
	if slotContent.name == "solariumstar" or slotContent.name == "thoriumrod" or slotContent.name == "enricheduranium" or slotContent.name == "enrichedplutonium" or slotContent.name == "ultronium" then
		if math.random(1,100) <= chance then world.debugText("DECAY",{myLocation[1]+2,myLocation[2]-3.5},"cyan"); return true end
	end	
	
	return false
end

function isn_doSlotDecay(slot)

	world.containerConsumeAt(entity.id(),slot,1) --consume resource

	local waste = world.containerItemAt(entity.id(),4)
	local tritium = world.containerItemAt(entity.id(),5)
	
	
	
	if (waste ~= nil) then
		-- sb.logInfo("Waste found in slot. Name is " .. waste.name)
		if (waste.name == "toxicwaste") then
		  -- sb.logInfo("increasing storage.radiation")
		  storage.radiation = storage.radiation + 5
		else
		  -- sb.logInfo("not toxic waste, ejecting")
		  world.containerConsumeAt(entity.id(),4,waste.count) --delete waste
		  world.spawnItem(waste.name,entity.position(),waste.count) --drop it on the ground
		end
	end
	local wastestack
	
	if (tritium ~= nil) then
		if (tritium.name == "tritium") then
		  storage.radiation = storage.radiation + 5
		else
		  world.containerConsumeAt(entity.id(),5,tritium.count) --delete waste
		  world.spawnItem(tritium.name,entity.position(),tritium.count) --drop it on the ground
		end
	end
        local tritiumstack
        
        
	if (waste == nil) then
		wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	elseif (waste.name == "toxicwaste") then
		wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	end


	if (tritium == nil) then
		if math.random(100) < storage.critChance then
		  tritiumstack = world.containerSwapItems(entity.id(),{name = "tritium", count = 1, data={}},5)
		  wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
		end	
	elseif (tritium.name == "tritium") and (math.random(100) < storage.critChance) then
		if math.random(100) < storage.critChance then
		  tritiumstack = world.containerSwapItems(entity.id(),{name = "tritium", count = 1, data={}},5)
		  wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
		end	
	end
	
	
	if (wastestack ~= nil) and (wastestack.count > 0) then
		world.spawnItem(wastestack.name,entity.position(),wastestack.count) --drop it on the ground
		storage.radiation = storage.radiation + 5
	end

	if (tritiumstack ~= nil) and (tritiumstack.count > 0) then
		world.spawnItem(tritiumstack.name,entity.position(),tritiumstack.count) --drop it on the ground
	end
	

	        
end

function isn_getCurrentPowerOutput(divide)
	if storage.batteryHold or not storage.active then return 0 end

	local divisor = isn_countPowerDevicesConnectedOnOutboundNode(0)
	if divisor < 1 then divisor = 1 end

	local powercount = 0
	powercount = powercount + isn_powerSlotCheck(0)
	powercount = powercount + isn_powerSlotCheck(1)
	powercount = powercount + isn_powerSlotCheck(2)
	powercount = powercount + isn_powerSlotCheck(3)
	
	if divide == true then return powercount / divisor
	else return powercount end
end

function onNodeConnectionChange()
	if isn_checkValidOutput() == true then object.setOutputNodeLevel(0, true)
	else object.setOutputNodeLevel(0, false) end
end