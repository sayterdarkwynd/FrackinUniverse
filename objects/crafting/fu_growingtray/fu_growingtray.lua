require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0
function init()
	transferUtil.init()
	object.setInteractive(true)
	
	if storage.growth == nil then storage.growth = 0 end
	if storage.water == nil then storage.water = 0 end
	if storage.fertSpeed == nil then storage.fertSpeed = false end
	if storage.fertYield == nil then storage.fertYield = false end
	if storage.fertSpeed2 == nil then storage.fertSpeed2 = false end
	if storage.fertYield2 == nil then storage.fertYield2 = false end
	if storage.fertSpeed3 == nil then storage.fertSpeed3 = false end
	if storage.fertYield3 == nil then storage.fertYield3 = false end
	if storage.harvestPool == nil then storage.harvestPool = "" end
	-- note: Need to go through and either have good place holder values or code that can handle bad vals.
	-- Also reformat the structure some...
	if storage.seedData == nil then	storage.seedData = {} end
	if storage.seedData.stages == nil then storage.seedData.stages = -1 end
	if storage.seedData.stage == nil then storage.seedData.stage = {} end
	if storage.seedData.resetStage == nil then storage.seedData.resetStage = -1 end
	if storage.growthData == nil then storage.growthData = {} end
	if storage.growthData.cap == nil then storage.growthData.cap = config.getParameter("isn_growthCap") end
	if storage.growthData.current == nil then storage.growthData.current = 0 end
	if storage.growthData.stage == nil then storage.growthData.stage = {} end
	if storage.yield == nil then storage.yield = 0 end	-- note: yield is now number of picks from pool
	--if storage.growthcap == nil then storage.growthcap = 100 end	-- placeholder, is set per stage.
	--if storage.growthcap == nil then storage.growthcap = config.getParameter("isn_growthCap") end
	
	if storage.activeConsumption == nil then storage.activeConsumption = false end
	storage.seedslot = 1
	storage.waterslot = 2
	storage.fertslot = 3
end

function isn_genGrowthData(initStage)
	if initStage == nil then initStage = 0 end
	storage.growthData.current = initStage
	storage.growthData.cap = 0
	for index = 0, storage.seedData.stages do
		local duration = storage.seedData.stage[tostring(index)]
	    if index >= initStage then
			--lua's random generator is inclusive to the given values and sticks to the type it was run with.
			storage.growthData.cap = storage.growthData.cap + math.random(duration["min"],duration["max"])
			storage.growthData.stage[tostring(index)] = storage.growthData.cap
		end
	end
	return
end

function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	
	storage.activeConsumption = false
	
	--if storage.currentseed == nil or storage.currentcrop == nil then
	if storage.currentseed == nil or storage.seedData.pool == nil then
		if isn_doSeedIntake() ~= true then return end
	end
	
	--local growthperc = isn_getXPercentageOfY(storage.growth,storage.growthcap)
	local growthperc = isn_getXPercentageOfY(storage.growth, storage.growthData.cap)
	if growthperc >= 75 then
		animator.setAnimationState("growth", "3")
	elseif growthperc >= 50 then
		animator.setAnimationState("growth", "2")
	elseif growthperc >= 25 then
		animator.setAnimationState("growth", "1")
	else
		animator.setAnimationState("growth", "0")
	end
	
	-- instead of water every tick we only check/use water every growth period.
	--if storage.water <= 0 and isn_doWaterIntake() ~= true then return end
	if storage.growth >= storage.growthData.stage[tostring(storage.growthData.current)] then
		if storage.water <= 0 and isn_doWaterIntake() ~= true then return end
		-- water situation is OK...
		storage.growthData.current = storage.growthData.current + 1
		if storage.growthData.current <= storage.seedData.stages then
			storage.water = storage.water - 1
		end
	end
	storage.activeConsumption = true
	storage.growth = storage.growth + 1
	if storage.fertSpeed == true then
		storage.growth = storage.growth + 1
	end
	if storage.fertSpeed2 == true then
	        storage.growth = storage.growth + 2
	end
	if storage.fertSpeed3 == true then
	        storage.growth = storage.growth + 3
	end
	if storage.growth >= storage.growthData.cap then
		-- spawn items from the treasurepool or silently fail...
		if root.isTreasurePool(storage.seedData.pool) then
			for i = 1, storage.yield do
				local itemDescriptors = root.createTreasure(storage.seedData.pool, world.threatLevel())
				for index, itemDescriptor in pairs(itemDescriptors) do
					fu_sendOrStoreItems(0, itemDescriptor)
					world.containerAddItems(entity.id(), itemDescriptor)
				end
			end
		end
		-- use up some fertilizer for the next planting...
		isn_doFertIntake()
		-- conditionally reset the growth of the current seed or use a seed and start up again.
		if storage.seedData.resetStage > 0 then
			storage.growth = 0
			isn_genGrowthData(storage.seedData.resetStage)
		else
			isn_doSeedIntake()
		end
		--[[
		-- if connected to an object receiver, try to send the crop, else store loally
		-- Wired Industry's item router is one such device
		fu_sendOrStoreItems(0, {name = storage.currentcrop, count = storage.yield}, {0, 1, 2})
		world.containerAddItems(entity.id(), {name = storage.currentseed, count = math.random(1,2), data={}})
		isn_doFertIntake()
		isn_doSeedIntake()
		]]--
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
	--storage.currentcrop = nil
	local contents = world.containerItems(entity.id())
	local seed = contents[storage.seedslot]
	
	if seed == nil then return false end
	local seedConfig = root.itemConfig(seed).config
	if seedConfig["objectType"] ~= "farmable" then return false end
	--store key properties of the seed.
	for key, value in pairs(seedConfig.stages) do
		if value.duration ~= nil then
			storage.seedData.stages = storage.seedData.stages+1
			storage.seedData.stage[tostring(storage.seedData.stages)] = {}
			storage.seedData.stage[tostring(storage.seedData.stages)].min = value.duration[1]
			storage.seedData.stage[tostring(storage.seedData.stages)].max = value.duration[2]
		else
			if value.harvestPool ~= nil then storage.seedData.pool = value.harvestPool end
			if value.resetToStage ~= nil then storage.seedData.resetStage = value.resetToStage end
		end
	end
	--set how many picks of the pool we get.
	storage.yield = 1
	--modify the number of picks by fertilizer in use.
	if storage.fertYield == true then storage.yield = storage.yield * 2 end
	if storage.fertYield2 == true then storage.yield = storage.yield * 3 end
	if storage.fertYield3 == true then storage.yield = storage.yield * 4 end
	--randomize our time to the next growth stage
	isn_genGrowthData()
	--storage.growthcap = randomduration(storage.seedData.stage[0])
	--consume a seed.
	world.containerConsume(entity.id(), {name = seed.name, count = 1, data={}})
	--note the seed...
	storage.currentseed = seed
	return true
	
	--[[
	for key, value in pairs(config.getParameter("isn_seedOutputs")) do
		if seed.name == key then
			storage.currentseed = key
			storage.currentcrop = value
			storage.yield = math.random(3,5)
			return true
		end
	end
	return false
	]]--
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