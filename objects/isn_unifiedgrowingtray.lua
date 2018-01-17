require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"
local deltaTime=0
function init()
	transferUtil.init()
	object.setInteractive(true)
	
	--Variables who's state are simple and can use values picked from nowhere safely.
	storage.growth = storage.growth or 0				--Plant growth completed
	storage.growthRate = storage.growthRate or 1		--Amount of growth per second
	storage.growthFluid = storage.growthFluid or 0		--Growth boost from fluids
	storage.growthFert = storage.growthFert or 0		--Growth boost from fertilizer
	storage.yield = storage.yield or 1					--harvestPool picks when grown
	storage.fluid = storage.fluid or 0					--Stored fluid
	storage.fluidUse = storage.fluidUse or 1			--Amount of fluid to use per stage
	storage.currentStage = storage.currentStage or 1	--Current plant stage
	storage.resetStage = storage.resetStage or 0		--Stage to jump back to post harvest (perennial)
	storage.hasFluid = storage.hasFluid or false		--If false soil is dry and no further growth.
	storage.hasTree = storage.hasTree or false			--Used to track if seed data is sapling/tree.
	--Checks which cause reset of growth data if failed
	if storage.currentseed ~= nil and storage.harvestPool ~= nil then
		--Storage.stages is the upper bound of the stage array
		if storage.stages == nil then isn_readSeedData() end
		--If Starbound stored stage keys as tostring(number), copy them back to keys of number.
		if type(storage.stage["1"]) == "table" then storage.stage[1] = storage.stage["1"] end
		if type(storage.stage["2"]) == "table" then storage.stage[2] = storage.stage["2"] end
		--storage.stage is information about each stage of the plant (only 1 and 2 are important).
		if type(storage.stage) ~= "table" then isn_readSeedData() end
		if type(storage.stage[1]) ~= "table" or
			type(storage.stage[2]) ~= "table" then isn_readSeedData() end
		--storage.stage[].min and storage.stage[].max are the range of times for a given stage.
		if storage.stage[1].min == nil or storage.stage[1].max == nil or
			storage.stage[2] == nil or storage.stage[2].max == nil then isn_readSeedData() end
		--storage.stage[].val is how long the current plant takes to reach the next stage.
		if storage.stage[1].val == nil or storage.stage[2].val == nil or
			storage.growthCap == nil then isn_genGrowthData() end
	end
	
	if storage.activeConsumption == nil then storage.activeConsumption = false end
	
	storage.seedslot = 1
	storage.waterslot = 2
	storage.fertslot = 3
end

--Config checkers
function handlesSaplings()
	return config.getParameter("isn_growSaplings") or false
end
function requiredPower()
	return config.getParameter("isn_requiredPower") or 0
end

--Returns active seed when tray is removed from world, much like how plants work.
function die()
	if storage.currentseed ~= nil then
		world.spawnItem(storage.currentseed, entity.position())
	end
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
	
	local growthmod = dt
	if requiredPower() > 0 then
		if power.consume(requiredPower()*dt) then
			animator.setAnimationState("powlight", "on")
		else
			growthmod = growthmod * 0.434782609
			animator.setAnimationState("powlight", "off")
		end
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
	
	--Check if a previous fluid use failed...
	if storage.hasFluid == false then storage.hasFluid = isn_doFluidConsume() end
	if storage.hasFluid ~= true then return end	--Failed again?  No growth nor outputs.
	
	storage.activeConsumption = true
	
	--Compute growth (we aren't dry right now)
	storage.growth = storage.growth + ((storage.growthRate + storage.growthFluid + storage.growthFert) * growthmod)
	
	--Check if we should try to use more fluid due to growth.
	--Since we only need to watch for transition from stage 1 to stage 2
	-- this is a lot simpler than it would need to be for more than 1 watch point.
	if storage.currentStage == 1 and storage.growth >= storage.stage[1].val then
		storage.hasFluid = isn_doFluidConsume()
		storage.currentStage = storage.currentStage + 1
	end
	
	--If the above fluid use left us dry stop here (don't output items) and try again later.
	--Yes this may generate 1 more (unnecessary) growth spurt but it won't use more fluid.
	if storage.hasFluid ~= true then return end
	
	--Check if we are grown.
	if storage.growth >= storage.growthCap then
		--Spawn our output...
		for i = 1, storage.yield do
			local itemDescriptors = nil
			if storage.hasTree == true then
				itemDescriptors = isn_genSaplingDrops()
			elseif root.isTreasurePool(storage.harvestPool) then
				itemDescriptors = root.createTreasure(storage.harvestPool, world.threatLevel())
			end
			if itemDescriptors ~= nil then
				for _, itemDescriptor in pairs(itemDescriptors) do
					local mask = {0, 1, 2}
					if itemDescriptor.name == storage.currentseed.name then
						mask = {1, 2}
					end
					fu_sendOrStoreItems(0, itemDescriptor, mask)
					--next line might not be necessary... was in original growingtray but not hydroponicstray code.
					--world.containerAddItems(entity.id(), itemDescriptor)
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
	if seedConfig.objectType ~= "farmable" then return nil end
	if seedConfig.objectName == "sapling" and handlesSaplings() ~= true then return nil end
	return seed
end

--Reads the currentseed's data.  Return false if there was a problem with the seed/data.
function isn_readSeedData()
	if storage.currentseed == nil then return false end
	local seedConfig = root.itemConfig(storage.currentseed).config
	storage.stages = 0
	storage.resetStage = 0
	storage.stage = {}
	storage.harvestPool = nil
	--Tree data
	storage.hasTree = false
	storage.stemDrops = nil
	storage.foliageDrops = nil
	--pairs() has an undefined order...
	local index = 1
	while seedConfig.stages[index] ~= nil do
		local curStage = seedConfig.stages[index]
		if type(curStage.duration) == "table" and index <= 2 then
			storage.stages = index
			local stage = {}
			stage.min = curStage.duration[1] or 10
			stage.max = curStage.duration[2] or stage.min
			storage.stage[index] = stage
		else
			if curStage.harvestPool ~= nil then storage.harvestPool = curStage.harvestPool end
			if curStage.resetToStage ~= nil then storage.resetStage = curStage.resetToStage + 1 end
			if curStage.tree ~= nil then 
				if curStage.tree == true then
					if isn_readSaplingData() == false then return false end
					storage.harvestPool = ""
				end
			end
		end
		index = index + 1
	end
	if index == 1 then return false end -- seed data was invalid.
	return true
end

--Reads sapling data and does minimal verification that we indeed have a valid sapling.
function isn_readSaplingData()
	if type(storage.currentseed.parameters) ~= "table" then return false end
	local stemType = storage.currentseed.parameters.stemName
	local foliageType = storage.currentseed.parameters.foliageName
	--Not sure if there is any saplings which only have one or the other of stem/foliage but
	-- just in case the aspects are separated.
	if stemType then
		local stemPath = root.treeStemDirectory(stemType)
		local stemJson = root.assetJson(stemPath .. stemType .. ".modularstem")
		storage.stemDrops = stemJson.dropConfig.drops
		storage.hasTree = true
	end
	if foliageType then
		local foliagePath = root.treeFoliageDirectory(foliageType)
		local foliageJson = root.assetJson(foliagePath .. foliageType .. ".modularfoliage")
		storage.foliageDrops = foliageJson.dropConfig.drops
		storage.hasTree = true
	end
	if storage.hasTree == true then return true end
	return false
end

--Generates drop data for a sapling
function isn_genSaplingDrops()
	--If I follow correctly, the stem and the foliage each can have a single drop
	--That drop is randomly picked from "dropConfig/drops"
	--Equal weight, each drop line is a single item.
	local drops = {}
	local dropCount = 1
	if type(storage.stemDrops) == "table" then
		drops[dropCount] = root.createItem(storage.stemDrops[math.random(1, #storage.stemDrops)][1], world.threatLevel())
		dropCount = dropCount + 1
	end
	if type(storage.foliageDrops) == "table" then
		drops[dropCount] = root.createItem(storage.foliageDrops[math.random(1, #storage.foliageDrops)][1], world.threatLevel())
		if drops[dropCount].name == "sapling" then drops[dropCount].parameters = storage.currentseed.parameters end
		dropCount = dropCount + 1
	end
	if dropCount == 1 then return nil end
	return drops
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
	--Trees always use new seeds...
	if storage.hasTree == true then return isn_doSeedIntake() end
	local seed = isn_readContainerSeed()
	--If the seed in the seed slot isn't what's being grown now, re-init growth.
	if seed ~= nil and storage.currentseed.name ~= seed.name then
		--give the perennial seed back before swapping plants
		fu_sendOrStoreItems(0, storage.currentseed, {0, 1, 2})
		return isn_doSeedIntake()
	end
	--If the current plant isn't perennial, re-init growth.
	if storage.resetStage < 1 then return isn_doSeedIntake() end
	
	storage.growth = 0
	
	--Read config data
	storage.growthRate = config.getParameter("isn_growthPerSecond")
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
	if isn_readSeedData() == false then
		storage.currentseed = nil
		return false 
	end
	
	--Read config data
	storage.growthRate = config.getParameter("isn_growthPerSecond")
	--Generate growth data.
	if isn_genGrowthData() == false then
		storage.currentseed = nil
		return false
	end
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