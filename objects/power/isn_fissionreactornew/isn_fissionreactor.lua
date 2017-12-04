require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"
require '/objects/isn_sharedobjectscripts.lua'

local deltaTime=0

function init()
    power.init()
	transferUtil.init()
	wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
	tritiumstack = world.containerSwapItems(entity.id(),{name = "tritium", count = 1, data={}},5)
        storage.critChance = 50
	object.setInteractive(true)
	radiation = {
	  {amount = 100, state = 'danger'},
	  {amount = 60, state = 'warn'},
	  {amount = 1, state = 'safe'},
	  {amount = 0, state = 'off'}
	}
	storage.radiation = storage.radiation or 0
	storage.active = true
end

function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	
	for i=1,#radiation do
	  if storage.radiation >= radiation[i].amount then
	    animator.setAnimationState("hazard", radiation[i].state)
	    break
	  end
	end

	if not storage.active then
		storage.radiation = math.max(storage.radiation - dt*5,0)
		animator.setAnimationState("screen", "off")
		power.update(dt)
		return
	end
	
	if isn_slotDecayCheck(0,1) then isn_doSlotDecay(0) end
	if isn_slotDecayCheck(1,1) then isn_doSlotDecay(1) end
	if isn_slotDecayCheck(2,1) then isn_doSlotDecay(2) end
	if isn_slotDecayCheck(3,1) then isn_doSlotDecay(3) end
	
	local powerout = isn_getCurrentPowerOutput()
	power.setPower(powerout)
	if powerout > 11 then
	  animator.setAnimationState("screen", "on")
	elseif powerout >= 6 then
	  animator.setAnimationState("screen", "med")
	elseif powerout >= 1 then
	  animator.setAnimationState("screen", "slow")
	elseif powerout <= 0 then
	  animator.setAnimationState("screen", "off")
	end
	
	local rads = -4 + powerout
	rads = rads > 0 and rads * 2 or rads
	if world.containerAvailable(entity.id(),"toxicwaste") >= 75 then
		rads = rads + 5
	end
	storage.radiation = math.min(storage.radiation + rads,120)

	local myLocation = entity.position()
	world.debugText("R:" .. storage.radiation, {myLocation[1]-1, myLocation[2]-2}, "red"); 

	-- the effects here don't addup in damage, just it creates more particles & more noise.
	-- therefore I think we could rework this for a single instance. sayter said that he or someone else
	-- could match this with the current radiation resistance
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
	power.update(dt)
end

function isn_powerSlotCheck(slotnum)
	-- any further edits has to keep in mind the ratio uranium to enriched uranium, plutonium to enriched plutonium, and solarium to ultronium
	fuel = {
	  biofuelcannister = 4,
	  biofuelcannisteradv = 4,
	  biofuelcannistermax = 5,
	  uraniumrod = 6,
	  neptuniumrod = 6,
	  tritium = 6,
	  deuterium = 7,
	  thoriumrod = 9, -- gets increased power from 7 to 9 (+28%), but loses in consumption rate, from 1/100 to 1/80 (-25%)
	  enricheduranium = 10, -- gets increased power from 8 to 10 + gain efficiency from 1/100 to 1/500
	  plutoniumrod = 10,
	  enrichedplutonium = 16, -- gets increased power from 12 to 16  + gain efficiency 5x
	  solariumstar = 19, -- gets higher power from 15 to 19 (+26%) but loses out in efficiency from 1/100 to 1/80 (-25%)
	  ultronium = 21 --  increased power from 20 to 21 & increased efficiency (5x)
	}
	return fuel[world.containerItemAt(entity.id(),slotnum) and world.containerItemAt(entity.id(),slotnum).name or 'nil'] or 0
end

function isn_slotDecayCheck(slot, chance)
	local slotContent = world.containerItemAt(entity.id(),slot)
	local myLocation = entity.position()

	--world.debugText("CHECK",{myLocation[1]-1,myLocation[2]-3.5},"cyan")

	if slotContent == nil then return false end

	if slotContent.name == "biofuelcannister" or slotContent.name == "biofuelcannisteradv" or slotContent.name == "biofuelcannistermax" then
		if math.random(1,60) <= chance then 
			--I have commented out the world.debugText cause that seems unecessary ???? Whismerhill
			--world.debugText("DECAY",{myLocation[1]+2,myLocation[2]-3.5},"cyan");
			return true
		end
	end
	
	if slotContent.name == "tritium" or slotContent.name == "deuterium" or slotContent.name == "uraniumrod" or slotContent.name == "plutoniumrod" or slotContent.name == "neptuniumrod" or slotContent.name == "thoriumrod" or slotContent.name == "solariumstar" then
		if math.random(1,80) <= chance then
			--world.debugText("DECAY",{myLocation[1]+2,myLocation[2]-3.5},"cyan");
			return true
		end
	end
	-- low decay rate gets even lower : from 1/100 to 1/500 e.g. fuel should be 5x more durable
	if slotContent.name == "enricheduranium" or slotContent.name == "enrichedplutonium" or slotContent.name == "ultronium" then
		if math.random(1,500) <= chance then 
			--world.debugText("DECAY",{myLocation[1]+2,myLocation[2]-3.5},"cyan");
			return true
		end
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
			if (math.random(100) < storage.critChance) then
				tritiumstack = world.containerSwapItems(entity.id(),{name = "tritium", count = 1, data={}},5)
				wastestack = world.containerSwapItems(entity.id(),{name = "toxicwaste", count = 1, data={}},4)
			end
		else
			local tritiumcount = tritium.count
			world.containerConsumeAt(entity.id(),5,tritiumcount) --delete waste
			world.spawnItem(tritium.name,entity.position(),tritiumcount) --drop it on the ground
		end
	elseif (math.random(100) < storage.critChance) then -- (tritium == nil)
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
	local powercount =  isn_powerSlotCheck(0)
	powercount = powercount + isn_powerSlotCheck(1)
	powercount = powercount + isn_powerSlotCheck(2)
	powercount = powercount + isn_powerSlotCheck(3)
	--object.say(powercount)
	return powercount
end
