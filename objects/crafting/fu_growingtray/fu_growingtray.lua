require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0
function init()
	transferUtil.init()
	object.setInteractive(true)

	if storage.growth == nil then storage.growth = 0 end
	if storage.water == nil then storage.water = 0 end
	if storage.fertSpeed == nil then storage.fertSpeed = 0 end
	if storage.fertYield == nil then storage.fertYield = 0 end
        if storage.liquidMod == nil then storage.liquidMod = 2 end
        if storage.seedMod == nil then storage.seedMod = 3 end
	if storage.yield == nil then storage.yield = 0 end
	if storage.growthcap == nil then storage.growthcap = config.getParameter("isn_growthCap") end
	if storage.activeConsumption == nil then storage.activeConsumption = false end

	storage.seedslot = 1
	storage.waterslot = 2
	storage.fertslot = 3	
end

function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end

	storage.activeConsumption = false
	
	if storage.currentseed == nil or storage.currentcrop == nil then
		if isn_doSeedIntake() ~= true then return end
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
	storage.growth = storage.growth + 1
	if storage.fertSpeed == 1 then
		storage.growth = storage.growth + 1
	end
	if storage.fertSpeed == 2 then
	        storage.growth = storage.growth + 2
	end
	if storage.fertSpeed == 3 then
	        storage.growth = storage.growth + 3
	end	
	if storage.growth >= storage.growthcap then
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
			world.containerConsume(entity.id(), {name = water.name, count = storage.liquidMod, data={}})
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
			if storage.fertYield == 1 then storage.yield = storage.yield * 2 end
			if storage.fertYield == 2 then storage.yield = storage.yield * 3 end
			if storage.fertYield == 3 then storage.yield = storage.yield * 4 end
			world.containerConsume(entity.id(), {name = seed.name, count = storage.seedMod, data={}})
			return true
		end
	end
	return false
end

function isn_doFertIntake()
	storage.fertSpeed = 0
	storage.fertYield = 0

	local contents = world.containerItems(entity.id())
	local fert = contents[storage.fertslot]
	if fert == nil then return false end
	
	for key, value in pairs(config.getParameter("isn_fertInputs")) do
		if fert.name == key then
			if value == 1 then --basic speed
				storage.fertSpeed = 1
				storage.liquidMod = 2
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 2 then -- basic yield
				storage.fertYield = 1
				storage.liquidMod = 2
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 3 then --basic speed, good yield
				storage.fertSpeed = 1
				storage.fertYield = 2
				storage.liquidMod = 2
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 4 then -- good speed, basic yield
				storage.fertSpeed = 2
				storage.fertYield = 1
				storage.liquidMod = 2
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 5 then -- great speed,good yield
				storage.fertSpeed = 3
				storage.fertYield = 2
				storage.liquidMod = 2
				storage.seedMod = 2
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true
			elseif value == 6 then -- great speed,great yield
				storage.fertSpeed = 2
				storage.fertYield = 3	
				storage.liquidMod = 2
				storage.seedMod = 1
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true	
			elseif value == 7 then -- low liquid consumption
				storage.liquidMod = 1	
				storage.fertSpeed = 1
				storage.fertYield = 1
				storage.seedMod = 2
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true	
			else
				storage.liquidMod = 2	
				storage.fertSpeed = 0
				storage.fertYield = 0
				storage.seedMod = 3
				world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
				return true			
			end
		end
	end
	return false
end