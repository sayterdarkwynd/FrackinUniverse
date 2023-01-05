require "/scripts/kheAA/transferUtil.lua"
require "/scripts/fupower.lua"
require "/scripts/effectUtil.lua"

function init()
	power.init()
	wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	tritiumstack = world.containerSwapItems(entity.id(),{name = "tritium", count = 1, data={}},5)
	object.setInteractive(true)
	radiationStates = {
		{amount = 100, state = 'danger'},
		{amount = 60, state = 'warn'},
		{amount = 1, state = 'safe'},
		{amount = 0, state = 'off'}
	}
	radiationRanges = {
		{range=16,power=120},
		{range=12,power=100},
		{range=8,power=80},
		{range=4,power=50}
	}
	powerStates = {
		{amount = 11, state = 'on'},
		{amount = 6, state = 'med'},
		{amount = 1, state = 'slow'},
		{amount = 0, state = 'off'}
	}
	storage.bonusWasteChance = config.getParameter("bonusWasteChance", 50)
	self.fuels = config.getParameter("fuels")
	storage.radiation = storage.radiation or 0
	storage.active = true
	storage.active2 = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
end

function onInputNodeChange(args)
	onNodeConnectionChange(args)
end

function onNodeConnectionChange(args)
	storage.active2 = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
	power.onNodeConnectionChange(nil,0)
end

function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	for _,dink in pairs(radiationStates) do
	if storage.radiation >= dink.amount then
		animator.setAnimationState("hazard", dink.state)
		break
	end
	end
	if (not storage.active) or (not storage.active2) then
		storage.radiation = math.max(storage.radiation - dt*5,0)
		animator.setAnimationState("screen", "off")
		power.setPower(0)
		power.update(dt)
		object.setAllOutputNodes(false)
		return
	end
	if storage.active2 then
		for i=0,3 do
			if isn_slotDecayCheck(i) then isn_doSlotDecay(i) end
		end
	end
	local powerout = isn_getCurrentPowerOutput()
	power.setPower(powerout)
	for _,dink in pairs(powerStates) do
	if powerout >= dink.amount then
		animator.setAnimationState("screen", dink.state)
		break
	end
	end
	local rads = -4 + powerout
	rads = (rads > 0) and (rads * 2) or rads
	if world.containerAvailable(entity.id(),"toxicwaste") >= 75 then
		rads = rads + 5
	end
	storage.radiation = math.min(storage.radiation + rads,120)
	local myLocation = entity.position()
	world.debugText("R:" .. storage.radiation, {myLocation[1]-1, myLocation[2]-2}, "red");
	-- the effects here don't addup in damage, just it creates more particles & more noise.
	-- therefore I think we could rework this for a single instance. sayter said that he or someone else
	-- could match this with the current radiation resistance
	--khe was here
	for _,dink in ipairs(radiationRanges) do
	if storage.radiation >= dink.power then
		effectUtil.projectileAllInRange("isn_fissionrads",dink.range)
		break
	end
	end
	object.setAllOutputNodes(powerout>0)
	power.update(dt)
end

function isn_powerSlotCheck(slotnum)
	local item = world.containerItemAt(entity.id(), slotnum)
	if not item then return 0 end
	return self and self.fuels and self.fuels[item.name] and self.fuels[item.name].power or 0
end

function isn_slotDecayCheck(slot)
	local item = world.containerItemAt(entity.id(),slot)
	if item and self and self.fuels and self.fuels[item.name] and math.random(1, self.fuels[item.name].decayRate) == 1 then
	return true
	end
	return false
end

function isn_doSlotDecay(slot)
	world.containerConsumeAt(entity.id(),slot,1) --consume resource
	local waste = world.containerItemAt(entity.id(),4)
	local tritium = world.containerItemAt(entity.id(),5)
	local wastestack
	local tritiumstack
	if waste then
		-- sb.logInfo("Waste found in slot. Name is " .. waste.name)
		if (waste.name == "toxicwaste") then
			-- sb.logInfo("increasing storage.radiation")
			storage.radiation = storage.radiation + 5
			wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
		else
			-- sb.logInfo("not toxic waste, ejecting")
			local wastecount = waste.count -- variable to ensure no change of quantities in between calculations.
			world.containerConsumeAt(entity.id(),4,wastecount) --delete waste
			world.spawnItem(waste.name,entity.position(),wastecount) --drop it on the ground
		end
	else -- (waste == nil)
		wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	end
	if tritium then
		if (tritium.name == "tritium") then
			storage.radiation = storage.radiation + 5
			if (math.random(100) < storage.bonusWasteChance) then
				tritiumstack = world.containerSwapItems(entity.id(),{name = "tritium", count = 1, data={}},5)
				wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
			end
		else
			local tritiumcount = tritium.count
			world.containerConsumeAt(entity.id(),5,tritiumcount) --delete waste
			world.spawnItem(tritium.name,entity.position(),tritiumcount) --drop it on the ground
		end
	elseif (math.random(100) < storage.bonusWasteChance) then -- (tritium == nil)
		tritiumstack = world.containerSwapItems(entity.id(),{name = "tritium", count = 1, data={}},5)
		wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	end
	if wastestack  and (wastestack.count > 0) then
		world.spawnItem(wastestack.name,entity.position(),wastestack.count) --drop it on the ground
		storage.radiation = storage.radiation + 5
	end
	if tritiumstack and (tritiumstack.count > 0) then
		world.spawnItem(tritiumstack.name,entity.position(),tritiumstack.count) --drop it on the ground
	end
end

function isn_getCurrentPowerOutput()
	if not storage.active then return 0 end
	local powercount = 0
	for i=0,3 do
		powercount = powercount + isn_powerSlotCheck(i)
	end
	--object.say(powercount)
	return powercount
end
