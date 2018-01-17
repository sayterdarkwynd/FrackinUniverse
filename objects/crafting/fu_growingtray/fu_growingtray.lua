require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0
function init()
	transferUtil.init()
	object.setInteractive(true)
	
	--variables who's state are simple and can use values picked from nowhere safely.
	storage.growth = storage.growth or 0
	storage.growthRate = storage.growthRate or 1
	storage.growthFluid = storage.growthFluid or 0
	storage.growthFert = storage.growthFert or 0
	storage.yield = storage.yield or 1
	storage.fluid = storage.fluid or 0
	storage.fluidUse = storage.fluidUse or 1
	storage.currentStage = storage.currentStage or 1
	storage.resetStage = storage.resetStage or 0
	storage.hasFluid = storage.hasFluid or false
	--This next check is necessary because of some inconsistencies in Starbound storage save/load.
	--Quite often when using a numeric key it loads back as string representation of number key.
	--Sometimes when using a string representation of number key it loads back as numeric key.
	local flagReadSeed = false
	local flagGenGrowth = false
	if storage.stage ~= nil and storage.stages ~= nil then
		local index = 1
		while index <= storage.stages do
			if type(storage.stage[tostring(index)]) ~= "nil" then
				storage.stage[index] = storage.stage[tostring(index)]
			end
			index = index + 1
		end
		--While we are here, verify the data looks valid...
		local stageLimit = math.min(2, storage.stages)
		while index <= stageLimit do
			if type(storage.stage[index]) == nil then
				flagReadSeed = true
				break
			end
			if storage.stage[index].min == nil or storage.stage[index].max == nil then
				flagReadSeed = true
				break
			end
			if storage.stage[index].val == nil then
				flagGenGrowth = true
				break
			end
		end
	end
	--Variables which require more work to initialize if invalid.
	if storage.stage == nil or storage.growthCap == nil or storage.stages == nil or flagReadSeed == true then
		storage.stage = {}
		if isn_readSeedData() == true then
			isn_genGrowthData()
			flagGenGrowth = false
		end
	end
	if flagGenGrowth == true then isn_genGrowthData() end
	
	if storage.activeConsumption == nil then storage.activeConsumption = false end
	
	storage.seedslot = 1
	storage.waterslot = 2
	storage.fertslot = 3
end

--Updates the state of the object.
function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	
	storage.activeConsumption = false
	
	--Try to start growing if data indicates we aren't.
	if storage.currentseed == nil or storage.harvestPool == nil then
		if isn_doSeedIntake() ~= true then return end
	end
	
	--Compute which graphic should be displayed and update.
	local growthperc = isn_getXPercentageOfY(storage.growth, storage.growthCap)
	if growthperc >= 75 then
		animator.setAnimationState("growth", "3")
	elseif growthperc >= 50 then
		animator.setAnimationState("growth", "2")
	elseif growthperc >= 25 then
		animator.setAnimationState("growth", "1")
	else
		animator.setAnimationState("growth", "0")
	end
	--Check if we need to consume some fluid and do so if needed.
	if storage.hasFluid == false or storage.growth >= storage.stage[storage.currentStage].val then
		--If somehow we skip over a stage, do multiple checks to use fluid.
		repeat
			storage.hasFluid = isn_doFluidConsume()
			--Don't change currentStage unless it's apt to.
			if storage.hasFluid == true and storage.growth >= storage.stage[storage.currentStage].val then
				storage.currentStage = storage.currentStage + 1
			end
		until (storage.hasFluid == false or storage.currentStage >= storage.stages or storage.growth < storage.stage[storage.currentStage].val)
	end
	--Stop here if we don't have fluid... (will retry later)
	if storage.hasFluid ~= true then return end
	
	storage.activeConsumption = true
	
	--Compute growth
	storage.growth = storage.growth + storage.growthRate + storage.growthFluid + storage.growthFert
	
	--Check if we are grown.
	if storage.growth >= storage.growthCap then
		--Spawn items from the treasurepool or silently fail due to invalid treasurePool...
		if root.isTreasurePool(storage.harvestPool) then
			for i = 1, storage.yield do
				local itemDescriptors = root.createTreasure(storage.harvestPool, world.threatLevel())
				for index, itemDescriptor in pairs(itemDescriptors) do
					fu_sendOrStoreItems(0, itemDescriptor)
					world.containerAddItems(entity.id(), itemDescriptor)
				end
			end
		end
		--Recycle the plant...
		isn_doRecyclePlant()
	end
	
end

--Updates internal fluid levels and modifies a growth variable depending on liquid in slot.
function isn_doWaterIntake()
	local contents = world.containerItems(entity.id())
	local water = contents[storage.waterslot]
	if water == nil then return false end
	
	for key, value in pairs(config.getParameter("isn_waterInputs")) do
		if water.name == key and type(value) == "table" then
			local amount, boost = value[1], value[2]
			if amount == nil or boost == nil then
				sb.logWarning("[fu_growingtray] found valid fluid named %s however either amount (%s) or boost (%s) was invalid.", key, amount, boost)
				return false
			end
			storage.fluid = storage.fluid + amount
			storage.growthFluid = boost
			world.containerConsume(entity.id(), {name = water.name, count = 1, data={}})
			return true
		end
	end
	return false
end

--Attempts to use up some fluid
function isn_doFluidConsume()
	if storage.fluid < storage.fluidUse then
		--Not enough internal fluid to keep growing, attempt to consume some liquid.
		--May need to consume multiple liquids to get fluid level high enough.
		while (storage.fluid < storage.fluidUse) do
			if isn_doWaterIntake() == false then return false end
		end
	end
	--Consume some fluid
	storage.fluid = storage.fluid - storage.fluidUse
	return true
end

--Fetch the seed from the storage slot, also does validity check.
function isn_readContainerSeed()
	local contents = world.containerItems(entity.id())
	local seed = contents[storage.seedslot]
	if seed == nil then return nil end
	--Reused the validity check here as it's useful to know if the seed is valid in almost every case.
	local seedConfig = root.itemConfig(seed).config
	if seedConfig["objectType"] ~= "farmable" then return nil end
	return seed
end

--Reads the currentseed's data.  Return false if there was a problem with the seed/data.
function isn_readSeedData()
	if storage.currentseed == nil then return false end
	local seedConfig = root.itemConfig(storage.currentseed).config
	if seedConfig["objectType"] ~= "farmable" then return false end
	storage.stages = 0
	storage.resetStage = 0
	--pairs() has an undefined order...
	local index = 1
	while seedConfig.stages[index] ~= nil do
		local curStage = seedConfig.stages[index]
		if type(curStage.duration) == "table" then
			storage.stages = index
			local stage = {}
			stage.min = curStage.duration[1] or 10
			stage.max = curStage.duration[2] or stage.min
			storage.stage[index] = stage
		else
			if curStage.harvestPool ~= nil then storage.harvestPool = curStage.harvestPool end
			if curStage.resetToStage ~= nil then storage.resetStage = curStage.resetToStage + 1 end
		end
		index = index + 1
	end
	if index == 1 then return false end -- seed data was invalid.
	return true
end

--[[
Generates growth data to tell when a plant is ready for harvest and when it uses fluid.
Notes:
-As a rule plants only have 2 growth stages.  Perennial plants should have a 3rd stage but
 not always (some mods skipped the data).  This stage is basically death stage but doesn't
 seem to be used.  Either way even perennial plants are harvestable after the 3rd stage and
 that's what matters.
]]--
function isn_genGrowthData(initStage)
	if initStage == nil then initStage = 1 end
	local maxStage = math.min(2, storage.stages)
	--Make sure some things make sense for a perennial, if not act like it's annual
	if initStage > storage.stages then
		--maybe toss something to the log...?
		initStage = 1
		storage.resetStage = 0
	end
	storage.currentStage = initStage
	storage.growthCap = 0
	local index = initStage
	while index <= maxStage do
		local stage = storage.stage[index]
		if type(stage) == nil then return false end
		storage.growthCap = storage.growthCap + math.random(stage.min, stage.max)
		stage.val = storage.growthCap
		index = index + 1
	end
	return true
end

--Init perennial plants (regrow stage)
--If the plant isn't perennial or there is a different (valid) seed in the seed slot, start from scratch.
function isn_doRecyclePlant()
	storage.growth = 0
	local seed = isn_readContainerSeed()
	--If the seed in the seed slot isn't what's being grown now, re-init growth.
	if seed ~= nil and storage.currentseed.name ~= seed.name then return isn_doSeedIntake() end
	--If the current plant isn't perennial, re-init growth.
	if storage.resetStage < 1 then return isn_doSeedIntake() end

	--Read config data
	storage.growthRate = config.getParameter("isn_growthPerTick")
	--Generate growth data, pass the resetStage along to make sure we only re-grow from that stage.
	isn_genGrowthData(storage.resetStage)
	--Set how many picks of the pool we get.
	storage.yield = 1
	--Consume some fertilizer (which modifies some stats)
	isn_doFertIntake()
	--Consume some fluid (which modifies some stats), order matters as fertilizer changes fluid needs.
	storage.hasFluid = isn_doFluidConsume()
	
	return true
end

--Initialize plant activity (start from scratch)
function isn_doSeedIntake()
	storage.growth = 0
	storage.currentseed = nil
	storage.harvestPool = nil
	
	--Read/init seed data
	local seed = isn_readContainerSeed()
	if seed == nil then return false end
	storage.currentseed = seed
	if isn_readSeedData() == false then return false end
	
	--Read config data
	storage.growthRate = config.getParameter("isn_growthPerTick")
	--Generate growth data.
	isn_genGrowthData()
	--Set default of how many picks of the pool we get.
	storage.yield = 1
	--Consume some fertilizer (which modifies some stats)
	isn_doFertIntake()
	--Consume some fluid (which modifies some stats), order matters as fertilizer changes fluid needs.
	storage.hasFluid = isn_doFluidConsume()
	--Consume a seed.
	world.containerConsume(entity.id(), {name = seed.name, count = 1, data={}})
	
	return true
end

--Consumes a unit of fertilizer and alters some variables based on what was consumed.
function isn_doFertIntake()
	local contents = world.containerItems(entity.id())
	local fert = contents[storage.fertslot]
	if fert == nil then return false end
	storage.fluidUse = 1
	storage.growthFert = 0
	
	for key, value in pairs(config.getParameter("isn_fertInputs")) do
		if fert.name == key and type(value) == "table" then
			local use, boost, yield = value[1], value[2], value[3]
			if use == nil or boost == nil or yield == nil then
				sb.logWarning("[fu_growingtray] Found valid fertilizer named %s however one of use (%s), boost (%s), or yield (%s) was invalid.", key, use, boost, yield)
				return false
			end
			storage.fluidUse = use
			storage.growthFert = boost
			storage.yield = storage.yield + yield
			world.containerConsume(entity.id(), {name = fert.name, count = 1, data={}})
			return true
		end
	end
	return false
end