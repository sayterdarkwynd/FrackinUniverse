require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"

local deltaTime=0
function init()
  power.init()
	transferUtil.init()
	object.setInteractive(true)
	
	storage.growth = storage.growth or 0
	storage.water = storage.water or 0
	storage.yield = storage.yield or 0
	storage.growthcap = storage.growthcap or config.getParameter("isn_growthCap")
	storage.activeConsumption = storage.activeConsumption or false
	storage.seedslot = 1
	storage.waterslot = 2
	storage.fertslot = 3
end

function update(dt)
  power.update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	storage.activeConsumption = false
	
	if storage.currentseed == nil or storage.currentcrop == nil then
		if isn_doSeedIntake() ~= true then animator.setAnimationState("powlight", "off") return end
	end
	
	if power.consume(config.getParameter('isn_requiredPower')*dt) then
	  growthmod = 1
	  animator.setAnimationState("powlight", "on")
	else
	  growthmod = 0.434782609
	  animator.setAnimationState("powlight", "off")
	end
	
	local growthperc = isn_getXPercentageOfY(storage.growth,storage.growthcap)
	if growthperc >= 75 then
		animator.setAnimationState("growth", "3")
	elseif growthperc >= 50 then
		animator.setAnimationState("growth", "2")
	elseif growthperc >= 25 then
		animator.setAnimationState("growth", "1")
	else
		animator.setAnimationState("growth", "0")
	end
	
	if storage.water <= 0 and isn_doWaterIntake() ~= true then return end
	storage.water = storage.water - 1
	storage.activeConsumption = true
	storage.growth = storage.growth + growthmod
	if storage.fertSpeed then
		storage.growth = storage.growth + growthmod
	end
	if storage.fertSpeed2 then
	        storage.growth = storage.growth + growthmod * 2
	end
	if storage.fertSpeed3 then
	        storage.growth = storage.growth + growthmod * 3
	end	
	if storage.growth >= storage.growthcap then
		-- if connected to an object receiver, try to send the crop, else store locally
		-- Wired Industry's item router is one such device
		fu_sendOrStoreItems(0, {name = storage.currentcrop, count = storage.yield}, {0, 1, 2})
		world.containerAddItems(entity.id(), {name = storage.currentseed, count = math.random(1,2), data={}})
		isn_doFertIntake()
		isn_doSeedIntake()
	end
end

function isn_doWaterIntake()
	local contents = world.containerItems(entity.id())
	local water = contents[storage.waterslot]
	if water == nil then return false end
	
	for key, value in pairs(config.getParameter("isn_waterInputs")) do
		if water.name == key then
			storage.water = value
			world.containerConsume(entity.id(), {name = water.name, count = 1, data={}})
			return true
		end
	end
	return false
end

function isn_doSeedIntake()
	storage.growth = 0
	storage.currentseed = nil
	storage.currentcrop = nil
	local contents = world.containerItems(entity.id())
	local seed = contents[storage.seedslot]
	if seed == nil then return false end
	
	for key, value in pairs(config.getParameter("isn_seedOutputs")) do
		if seed.name == key then
			storage.currentseed = key
			storage.currentcrop = value
			storage.yield = math.random(3,5)
			if storage.fertYield then storage.yield = storage.yield * 2
			elseif storage.fertYield2 then storage.yield = storage.yield * 3
			elseif storage.fertYield3 then storage.yield = storage.yield * 4 end
			world.containerConsume(entity.id(), {name = seed.name, count = 1, data={}})
			return true
		end
	end
	return false
end

function isn_doFertIntake()
	storage.fertSpeed = false
	storage.fertYield = false
	storage.fertSpeed2 = false
	storage.fertYield2 = false
	storage.fertSpeed3 = false
	storage.fertYield3 = false
	local contents = world.containerItems(entity.id())
	local fert = contents[storage.fertslot]
	if fert == nil then return false end
	
	for key, value in pairs(config.getParameter("isn_fertInputs")) do
		if fert.name == key then
			if value == 1 then
				storage.fertSpeed = true
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 2 then
				storage.fertYield = true
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 3 then
				storage.fertSpeed = true
				storage.fertYield = true
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 4 then
				storage.fertSpeed2 = true
				storage.fertYield2 = true
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			else
				storage.fertSpeed3 = true
				storage.fertYield3 = true				
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			end
		end
	end
	return false
end