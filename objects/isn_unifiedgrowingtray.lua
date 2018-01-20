require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"
local deltaTime=0
local fastForwardSeconds = 600 -- Typical chunk to fast forward by, 10 minutes
local maxFastForwardSeconds = 3600 -- Maximum total time allowed to fast forward, 1 hour
local minFastForwardSeconds = 60 -- Minimum allowed time to fastforward before we just give up and let the power fail.
function init()
	if cRequiredPower() > 0 then power.init() end
	transferUtil.init()
	object.setInteractive(true)
	
	--Variables who's state is configurable.
	storage.growthRate = storage.growthRate or cGrowthRate()	--Amount of growth per second
	storage.seedUse = storage.seedUse or cSeedUse()				--Number of seeds to use per cycle
	storage.yield = storage.yield or cYield()					--harvestPool picks when grown
	storage.fluidUse = storage.fluidUse or cFluidUse()			--Amount of fluid to use per stage
	
	--Variables who's state are simple and can use values picked from nowhere safely.
	storage.growth = storage.growth or 0 				--Plant growth completed
	storage.growthFluid = storage.growthFluid or 0		--Growth boost from fluids
	storage.growthFert = storage.growthFert or 0		--Growth boost from fertilizer
	storage.fluid = storage.fluid or 0					--Stored fluid
	storage.currentStage = storage.currentStage or 1	--Current plant stage
	storage.resetStage = storage.resetStage or 0		--Stage to jump back to post harvest (perennial)
	storage.hasFluid = storage.hasFluid or false		--If false soil is dry and no further growth.
	storage.hasTree = storage.hasTree or false			--Used to track if seed data is sapling/tree.
	
	if storage.activeConsumption == nil then storage.activeConsumption = false end
	
	storage.seedslot = 1
	storage.waterslot = 2
	storage.fertslot = 3
	
	--Checks which cause reset of seed/growth data if failed,
	--placed at end so we can return without breaking any other init stuff.
	if storage.currentseed ~= nil and storage.harvestPool ~= nil then
		--Storage.stages is the upper bound of the stage array
		if storage.stages == nil then
			if isn_readSeedData() == false then
				storage.currentseed = nil
				return
			end
		end
		--storage.stage is information about each stage of the plant.
		if type(storage.stage) ~= "table" then
			if isn_readSeedData() == false then
				storage.currentseed = nil
				return
			end
		end
		--If Starbound stored stage keys as tostring(number), copy them back to keys of number.
		for i = 1, storage.stages do
			if type(storage.stage[tostring(i)]) == "table" then
				storage.stage[i] = storage.stage[tostring(i)]
			end
			if type(storage.stage[i]) ~= table then isn_readSeedData() end
			--storage.stage[].min and storage.stage[].max are the range of times for a given stage.
			if storage.stage[i].min == nil or storage.stage[i].max == nil then
				if isn_readSeedData() == false then
					storage.currentseed = nil
					return
				end
			end
			--storage.stage[].val is how long the current plant takes to reach the next stage.
			if storage.stage[i].val == nil then isn_genGrowthData() end
		end
	end
end

--Config checkers
function cHandlesSaplings()
	return config.getParameter("isn_growSaplings") or false
end
function cRequiredPower()
	return config.getParameter("isn_requiredPower") or 0
end
function cGrowthRate()
	return config.getParameter("isn_baseGrowthPerSecond") or 4
end
function cSeedUse()
	return config.getParameter("isn_defaultSeedUse") or 4
end
function cYield()
	return config.getParameter("isn_baseYields") or 4
end
function cFluidUse()
	return config.getParameter("isn_defaultWaterUse") or 4
end

--Returns active seed when tray is removed from world, much like how plants
--work.
function die()
	if storage.currentseed ~= nil then
		local count = storage.seedUse or cSeedUse()
		world.spawnItem(storage.currentseed, entity.position(), count)
	end
end

--Updates the state of the object.
function update(dt)
	local powerReq = cRequiredPower()
	if powerReq > 0 then power.update(dt) end
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	
	storage.activeConsumption = false
	
	--Try to start growing if data indicates we aren't.
	if storage.currentseed == nil or storage.harvestPool == nil then
		--Clear the lastWorldTime so we don't get free fast forwards after not
		--having a seed for an hour or so...
		--We do this here and not in isn_doSeedIntake to preserve fast forward data.
		storage.lastWorldTime = nil
		if isn_doSeedIntake() ~= true then return end
	end
	
	--Figure out how long it's been since our last update.
	local secondsThisUpdate = dt
	if storage.lastWorldTime ~= nil then
		secondsThisUpdate = world.time() - storage.lastWorldTime
		if secondsThisUpdate < 0 then secondsThisUpdate = dt end
	end
	storage.lastWorldTime = world.time()
	
	--Don't allow infinite fast forward time.
	if secondsThisUpdate > maxFastForwardSeconds then secondsThisUpdate = maxFastForwardSeconds end
	
	--Use this to fast forward in increments.  This is intentionally lossy since accuracy costs server load.
	if secondsThisUpdate > fastForwardSeconds then
		storage.lastWorldTime = storage.lastWorldTime - (secondsThisUpdate - fastForwardSeconds)
		secondsThisUpdate = fastForwardSeconds
	end
	
	--Adjust our fast forward time by available power...
	local availPower = power.getTotalEnergy()
	if powerReq * secondsThisUpdate > availPower and availPower >= minFastForwardSeconds * powerReq then
		local pwrIncrement = availPower / powerReq
		storage.lastWorldTime = storage.lastWorldTime - (secondsThisUpdate - pwrIncrement)
		secondsThisUpdate = pwrIncrement
	end
	
	sb.logInfo("power %s", power.getTotalEnergy())
	
	--useful for debugging...
	--sb.logInfo("[%s], growth %s/%s seconds %s", storage.currentseed.name, storage.growth, storage.growthCap, secondsThisUpdate)
	
	local growthmod = secondsThisUpdate
	if powerReq > 0 then
		if power.consume(powerReq*secondsThisUpdate) then
			animator.setAnimationState("powlight", "on")
		else
			sb.logInfo("insufficient power...")
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
	if storage.currentStage < storage.stages then
		--multiple stages might have happened, make sure we use apt fluid before resuming flow.
		while true do
			if storage.currentStage >= storage.stages then break end
			if storage.growth < storage.stage[storage.currentStage].val then break end
			if storage.hasFluid == false then break end
			storage.hasFluid = isn_doFluidConsume()
			storage.currentStage = storage.currentStage + 1
		end
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

--Updates internal fluid levels and modifies a growth variable depending on
--liquid in slot.
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
		--Not enough internal fluid to keep growing, attempt to consume an item.
		--May need to consume multiple items to get fluid level high enough.
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
	if seedConfig.objectName == "sapling" and cHandlesSaplings() ~= true then return nil end
	return seed
end

--Reads the currentseed's data.  Return false if there was a problem with the
--seed/data.
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
		if type(curStage.duration) == "table" then
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

--Reads sapling data and does minimal verification that we indeed have a valid
--sapling.
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

--Generates growth data to tell when a plant is ready for harvest and when it
--needs to be watered.
function isn_genGrowthData(initStage)
	if initStage == nil then initStage = 1 end
	--Make sure some things make sense for a perennial, if not act like it's annual
	if initStage > storage.stages then
		--maybe toss something to the log...?
		initStage = 1
		storage.resetStage = 0
	end
	storage.currentStage = initStage
	storage.growthCap = 0
	local index = initStage
	while index <= storage.stages do
		local stage = storage.stage[index]
		if type(stage) == nil then return false end
		storage.growthCap = storage.growthCap + math.random(stage.min, stage.max)
		stage.val = storage.growthCap
		index = index + 1
	end
	return true
end

--Init perennial plants (regrow stage)
--If the plant isn't perennial or there is a different (valid) seed in the seed
--slot, start from scratch.
function isn_doRecyclePlant()
	--Trees always use new seeds...
	if storage.hasTree == true then return isn_doSeedIntake() end
	
	local seed = isn_readContainerSeed()
	--If the seed in the seed slot isn't what's being grown now, re-init growth.
	if seed ~= nil then
		if storage.currentseed.name ~= seed.name then
			--give the perennial seed back before swapping plants
			local count = storage.seedUse or cSeedUse()
			local descriptor = {name = storage.currentseed.name, count = count, data={}}
			fu_sendOrStoreItems(0, descriptor, {0, 1, 2})
			return isn_doSeedIntake()
		end
	end
	--If the current plant isn't perennial, re-init growth.
	if storage.resetStage < 1 then
		return isn_doSeedIntake()
	end
	
	storage.growth = 0
	
	--set defaults that fertilizer can change or modify
	storage.growthRate = cGrowthRate()
	storage.fluidUse = cFluidUse()
	storage.seedUse = cSeedUse()
	storage.yield = cYield()
	
	local oldSeedCount = storage.seedUse
	local fertName = isn_doFertProcess()
	if oldSeedCount > storage.seedUse then
		--Give back seeds the new fertilizer doesn't need.
		local descriptor = {name = storage.currentseed.name, count = (oldSeedCount - storage.seedUse), data={}}
		fu_sendOrStoreItems(0, descriptor, {1, 2})
	elseif oldSeedCount < storage.seedUse then
		--Give back all the seeds and restart growth since we need more seeds.
		local descriptor = {name = storage.currentseed.name, count = oldSeedCount, data={}}
		fu_sendOrStoreItems(0, descriptor, {1, 2})
		return isn_doSeedIntake()
	end
	
	--Generate growth data.
	if isn_genGrowthData() == false then
		storage.currentseed = nil
		storage.harvestPool = nil
		return false
	end
	--All state tests passed and we are ready to continue growing, consume some items.
	
	--Consume a unit of fertilizer.
	if fertName ~= nil then
		world.containerConsume(entity.id(), {name = fertName, count = 1, data={}})
	end
	--Consume some fluid.
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
	
	--set defaults that fertilizer can change or modify
	storage.growthRate = cGrowthRate()
	storage.fluidUse = cFluidUse()
	storage.seedUse = cSeedUse()
	storage.yield = cYield()
	
	--Since we might need to consume multiple seeds we delay fertilizer USE
	--until we know we have enough resources to proceed.
	--Otherwise we could end up consuming all the fertilizer without growing anything.
	local fertName = isn_doFertProcess()
	
	--verify we have enough seeds to proceed.
	if storage.currentseed.count < storage.seedUse then
		storage.currentseed = nil
		storage.harvestPool = nil
		return false
	end
	
	--Generate growth data.
	if isn_genGrowthData() == false then
		storage.currentseed = nil
		storage.harvestPool = nil
		return false
	end
	--All state tests passed and we are ready to grow, consume some items.
	
	--Consume a unit of fertilizer.
	if fertName ~= nil then
		world.containerConsume(entity.id(), {name = fertName, count = 1, data={}})
	end
	--Consume some fluid.
	storage.hasFluid = isn_doFluidConsume()
	--Consume a seed.
	world.containerConsume(entity.id(), {name = seed.name, count = storage.seedUse, data={}})
	
	return true
end

--Reads the current fertilizer slot and modifies growing state data based on
--what is found there.
--Returns nil if nothing to do, otherwise a string of the itemname to be used.
function isn_doFertProcess()
	local contents = world.containerItems(entity.id())
	local fert = contents[storage.fertslot]
	if fert == nil then return nil end
	storage.fluidUse = 1
	storage.growthFert = 0
	
	for key, value in pairs(config.getParameter("isn_fertInputs")) do
		if fert.name == key and type(value) == "table" then
			local seeds, use, boost, yield = value[1], value[2], value[3], value[4]
			if use == nil or boost == nil or yield == nil then
				sb.logWarning("[fu_growingtray] Found valid fertilizer named %s however one of the following are invalid:", key)
				sb.logWarning("                 use (%s), boost (%s), or yield (%s) was invalid.", seeds, use, boost, yield)
				return nil
			end
			storage.seedUse = seeds
			storage.fluidUse = use
			storage.growthFert = boost
			storage.yield = storage.yield + yield
			return fert.name
		end
	end
	return nil
end