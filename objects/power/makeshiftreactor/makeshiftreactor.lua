require "/scripts/kheAA/transferUtil.lua"
require "/scripts/fupower.lua"
require "/scripts/effectUtil.lua"
require "/scripts/vec2.lua"


function init()
    power.init()
	wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	object.setInteractive(true)
	
	radiationStates = {
		{amount = 140, state = 'danger'},
		{amount = 75, state = 'warn'},
		{amount = 1, state = 'safe'},
		{amount = 0, state = 'off'}
	}
	
	radiationRanges = {
		{range=16,power=80},
		{range=12,power=60},
		{range=8,power=40},
		{range=4,power=20}
	}
	
	powerStates = {
		{amount = 16, state = 'on'},
		{amount = 9, state = 'med'},
		{amount = 1, state = 'slow'},
		{amount = 0, state = 'off'}
	}
	
    storage.maxHeat = config.getParameter("maxHeat", 200)


	
	storage.currentHeat = storage.currentHeat or 0
	
    storage.bonusWasteChance = config.getParameter("bonusWasteChance", 50)
    storage.fuels = config.getParameter("fuels")
    storage.coolant = config.getParameter("coolant")
	
	storage.radiation = storage.radiation or 0
	storage.active = true
	storage.active2 = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
	self.timerPowerReduced = 0
end

function onInputNodeChange(args)
	storage.active2 = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
end

function onNodeConnectionChange(args)
	storage.active2 = (not object.isInputNodeConnected(0)) or object.getInputNodeLevel(0)
end



function update(dt)
	if self.timerFusionDisabled then 
		self.timerFusionDisabled = self.timerFusionDisabled - 1
	end

	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end

	for _,dink in pairs(radiationStates) do
        if storage.currentHeat >= dink.amount then
            animator.setAnimationState("hazard", dink.state)
            break
        end
	end

	if (not storage.active) or (not storage.active2) then
		storage.radiation = math.max(storage.radiation - dt*5,0)
		animator.setAnimationState("screen", "off")
		animator.setAnimationState("screenbright", "off")		
		power.setPower(0)
		power.update(dt)
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
	storage.currentHeat = math.min(storage.currentHeat + (powerout/2),storage.maxHeat)
	isn_slotCoolantCheck(5)
	
	for _,dink in ipairs(radiationRanges) do
        if storage.radiation >= dink.power then
			effectUtil.projectileAllInRange("isn_fissionrads",dink.range)
            break
        end
	end
	
	power.update(dt)
end

function isn_slotDecayCheck(slot)
	local item = world.containerItemAt(entity.id(),slot)
	local myLocation = entity.position()

    if item and storage.fuels[item.name] and math.random(1, storage.fuels[item.name].decayRate) == 1 then
        return true
    end

	return false
end



function isn_powerSlotCheck(slotnum)
    local item = world.containerItemAt(entity.id(), slotnum)
    if not item then return 0 end
	return storage.fuels[item.name] and storage.fuels[item.name].power or 0
end

function isn_slotCoolantCheck(slot)
	

	local item = world.containerItemAt(entity.id(),slot)
	local myLocation = entity.position()

    if item and storage.coolant[item.name] and storage.currentHeat > 50 then
		storage.currentHeat = storage.currentHeat - (50)
		world.containerConsumeAt(entity.id(),slot,1) --consume resource	
	end
	
	animator.setAnimationRate(0.7 + 0.01*storage.currentHeat)
		
	if storage.currentHeat >= storage.maxHeat then
	    world.spawnProjectile(config.getParameter("explosionProjectile", "reactormeltdown"), vec2.add(object.position(), config.getParameter("explosionOffset", {0,0})), entity.id(), {0,0})	
		--object.smash(true)   --object is no longer detonated
		storage.radiation = storage.radiation + 15  --large rad increase
		storage.currentHeat = 1  --reset heat
		power.setPower(0)
		power.update(dt)
		self.timerPowerReduced = 10
    end
	
end

function isn_doSlotDecay(slot)

	world.containerConsumeAt(entity.id(),slot,1) --consume resource

	local waste = world.containerItemAt(entity.id(),4)
	local wastestack

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


	if wastestack  and (wastestack.count > 0) then
		world.spawnItem(wastestack.name,entity.position(),wastestack.count) --drop it on the ground
		storage.radiation = storage.radiation + 5
	end


end

function isn_getCurrentPowerOutput()
		if not storage.active then return 0 end
	    local powercount = 0
	    for i=0,3 do
	        powercount = powercount + isn_powerSlotCheck(i)
	    end
	    if self.timerPowerReduced >= 1 then 
		  self.timerPowerReduced = self.timerPowerReduced -1
		  powercount = 0 
		end
		--object.say(powercount)
		return powercount		
end
