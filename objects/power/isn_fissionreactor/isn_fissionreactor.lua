function init(virtual)
	if virtual == true then return end
	object.setInteractive(true)
	
	if storage.radiation == nil then storage.radiation = 0 end
	if storage.active == nil then storage.active = true end
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

	if storage.radiation >= 100 then
		animator.setAnimationState("hazard", "danger")
	elseif storage.radiation >= 60 then
		animator.setAnimationState("hazard", "warn")
	elseif storage.radiation >= 1 then
		animator.setAnimationState("hazard", "safe")
	else 
	        animator.setAnimationState("hazard", "off")
	end

	if storage.active == false then
		storage.radiation = storage.radiation - 5
		storage.radiation = isn_numericRange(storage.radiation,0,100)
		animator.setAnimationState("screen", "off")
		return
	end
	
	if isn_slotDecayCheck(0,5) == true then isn_doSlotDecay(0) end
	if isn_slotDecayCheck(1,5) == true then isn_doSlotDecay(1) end
	if isn_slotDecayCheck(2,5) == true then isn_doSlotDecay(2) end
	if isn_slotDecayCheck(3,5) == true then isn_doSlotDecay(3) end
	
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
	if waste >= 75 then
		rads = rads + 5
	end
	storage.radiation = storage.radiation + rads
	storage.radiation = isn_numericRange(storage.radiation,0,100)

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
	if slotContent.name == "biofuelcannister" then return 1
	elseif slotContent.name == "biofuelcannisteradv" then return 2
	elseif slotContent.name == "biofuelcannistermax" then return 3
	elseif slotContent.name == "uraniumrod" then return 2
	elseif slotContent.name == "neptuniumrod" then return 3
	elseif slotContent.name == "enricheduranium" then return 3
	elseif slotContent.name == "plutoniumrod" then return 3
	elseif slotContent.name == "enrichedplutonium" then return 4
	elseif slotContent.name == "thoriumrod" then return 4
	elseif slotContent.name == "solariumstar" then return 4
	elseif slotContent.name == "ultronium" then return 5
	else return 0 end	
end

function isn_slotDecayCheck(slot, chance)
	local contents = world.containerItems(entity.id())
	local slotContent = world.containerItemAt(entity.id(),slot)


	if slotContent == nil then return false end

	if slotContent.name == "biofuelcannister" or slotContent.name == "biofuelcannisteradv" or slotContent.name == "biofuelcannistermax" then
		if math.random(1,60) <= chance then return true end
	end
	
	if slotContent.name == "uraniumrod" or slotContent.name == "plutoniumrod" then
		if math.random(1,80) <= chance then return true end
	end	
	
	if slotContent.name == "solariumstar" or slotContent.name == "enricheduranium" or slotContent.name == "enrichedplutonium" or slotContent.name == "ultronium" then
		if math.random(1,100) <= chance then return true end
	end	
	
	return false
end

function isn_doSlotDecay(slot)

	world.containerConsumeAt(entity.id(),slot,1) --consume resource

	local waste = world.containerItemAt(entity.id(),4)
	
	if waste ~= nil then
		-- sb.logInfo("Waste found in slot. Name is " .. waste.name)
		if waste.name == "toxicwaste" then
		  storage.radiation = storage.radiation + 5
		else
		  world.containerConsumeAt(entity.id(),4,waste.count) --delete waste
		  world.spawnItem(waste.name,entity.position(),waste.count) --drop it on the ground
		end
	end

	local wastestack
	
	if waste == nil then
		wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	elseif waste.name == "toxicwaste" then
		wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	end
	
	if wastestack ~= nil then
		world.spawnItem(wastestack.name,entity.position(),wastestack.count) --drop it on the ground
		storage.radiation = storage.radiation + 5
	end
end

function isn_getCurrentPowerOutput(divide)
	if storage.active == false then return 0 end
	
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