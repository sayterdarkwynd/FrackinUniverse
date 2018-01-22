require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"
local deltaTime=0
function init()
	self.requiredPower = config.getParameter("isn_requiredPower")
	if type(self.requiredPower) ~= "number" then self.requiredPower = 0 end
	self.handlesSaplings = config.getParameter("isn_growSaplings") or false
	if type(self.handlesSaplings) ~= "boolean" then self.handlesSaplings = false end
	self.baseGPS = config.getParameter("isn_baseGrowthPerSecond")
	if type(self.baseGPS) ~= "number" or self.baseGPS <= 0 then self.baseGPS = 4 end
	self.seedUse = config.getParameter("isn_defaultSeedUse")
	if type(self.seedUse) ~= "number" or self.seedUse < 1 then self.seedUse = 4 end
	self.baseYield = config.getParameter("isn_baseYields")
	if type(self.baseYield) ~= "number" or self.baseYield < 1 then self.baseYield = 4 end
	self.defaultFluidUse = config.getParameter("isn_defaultWaterUse")
	if type(self.defaultFluidUse) ~= "number" or self.defaultFluidUse <= 0 then
			self.defaultFluidUse = 4 end
	self.unpoweredGrowthRate = config.getParameter("isn_unpoweredGrowthRate")
	if type(self.unpoweredGrowthRate) ~= "number" or self.unpoweredGrowthRate <= 0 then
			self.unpoweredGrowthRate = 0.434782609 end
	self.maxFastForwardSeconds = config.getParameter("isn_maxFastForwardSeconds")
	if type(self.maxFastForwardSeconds) ~= "number" then self.maxFastForwardSeconds = 6000
	
	if self.requiredPower > 0 then
		self.freePowerSeconds = config.getParameter("isn_freePowerSeconds") or 10
		local scriptDelta = config.getParameter("scriptDelta") or 1 --Validity of this should be handled by Starbound.
		local minTime = 2 * scriptDelta
		if type(self.freePowerSeconds) ~= "number" or self.freePowerSeconds < minTime then
				self.freePowerSeconds = minTime end
		if self.maxFastForwardSeconds < self.freePowerSeconds then
				self.maxFastForwardSeconds = self.freePowerSeconds end
		power.init()
	end
	
	transferUtil.init()
	object.setInteractive(true)
	
	--Variables who's state is configurable.
	storage.growthRate = storage.growthRate or self.baseGPS		--Amount of growth per second
	storage.seedUse = storage.seedUse or self.seedUse			--Number of seeds to use per cycle
	storage.yield = storage.yield or self.baseYield				--harvestPool picks when grown
	storage.fluidUse = storage.fluidUse or self.defaultFluidUse	--Amount of fluid to use per stage
	
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
	if storage.currentseed and storage.harvestPool then
		--Storage.stages is the upper bound of the stage array
		--storage.stage is information about each stage of the plant.
		if ( not storage.stages or type(storage.stage) ~= "table" ) and not isn_readSeedData() then
			storage.currentseed = nil
			return
		end
		--If Starbound stored stage keys as tostring(number), copy them back to keys of number.
		for i = 1, storage.stages do
			if type(storage.stage[tostring(i)]) == "table" then
				storage.stage[i] = storage.stage[tostring(i)]
			end
		end
		--Make sure each element of seed data is valid.
		for i = 1, storage.stages do
			--storage.stage[].min and storage.stage[].max are the range of times for a given stage.
			--storage.stage[].val is how long the current plant takes to reach the next stage.
			if type(storage.stage[i]) ~= table or not (storage.stage[i].min and storage.stage[i].max) then
				if not isn_readSeedData() then
					storage.currentseed = nil
					return
				end
				break
			end
		end
		--Make sure growth data is valid.
		for i = 1, storage.stages do
			if not storage.stage[i].val then
				if not isn_genGrowthData() then
					storage.currentseed = nil
					return
				end
				break
			end
		end
	end
end

--Returns active seed when tray is removed from world, much like how plants
--work.
function die()
	if storage.currentseed then
		local count = storage.seedUse or self.seedUse
		world.spawnItem(storage.currentseed, entity.position(), count)
	end
end

--Updates the state of the object.
function update(dt)
	if self.requiredPower > 0 then power.update(dt) end
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
	
	storage.activeConsumption = false
	
	--Try to start growing if data indicates we aren't.
	if not (storage.currentseed and storage.harvestPool) then
		storage.lastWorldTime = nil
		if not isn_doSeedIntake() then return end
	end
	
	--Figure out how long it's been since our last update.
	local secondsThisUpdate = dt
	if storage.lastWorldTime then
		secondsThisUpdate = world.time() - storage.lastWorldTime
		if secondsThisUpdate < 0 then secondsThisUpdate = dt end
	end
	storage.lastWorldTime = world.time()
	
	--Don't allow infinite fast forward time.
	secondsThisUpdate = math.min(secondsThisUpdate, self.maxFastForwardSeconds)
	
	--useful for debugging...
	--sb.logInfo("[%s], growth %s/%s seconds this update %s", storage.currentseed.name, storage.growth, storage.growthCap, secondsThisUpdate)
	
	local growthmod = secondsThisUpdate
	
	if self.requiredPower > 0 then
		if (secondsThisUpdate <= self.freePowerSeconds) then
			--Adjust our fast forward time by available power...
			if power.consume(self.requiredPower * dt) then
				animator.setAnimationState("powlight", "on")
			else
				growthmod = growthmod * self.unpoweredGrowthRate
				animator.setAnimationState("powlight", "off")
			end
		else 
			growthmod = growthmod * self.unpoweredGrowthRate
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
	if not storage.hasFluid then
		storage.hasFluid = isn_doFluidConsume()
		if not storage.hasFluid then return end --Failed again?  No growth nor outputs.
	end
	
	storage.activeConsumption = true
	
	if storage.currentStage <= storage.stages then
		local deltaGrowth = (storage.growthRate + storage.growthFluid + storage.growthFert) * growthmod
		local newGrowth = storage.growth + deltaGrowth
		if newGrowth > storage.stage[storage.currentStage].val then
			local refundTime
			local growthDif
			local failToStages = false
			if newGrowth > storage.growthCap then
				local stageDif = storage.stages - storage.currentStage
				growthDif = newGrowth - storage.growthCap
				local hasFluid = true
				if stageDif > 0 then hasFluid = isn_doFluidConsume(stageDif) end
				if not hasFluid then failToStages = true end
			else
				failToStages = true
			end
			if failToStages then
				growthDif = newGrowth - storage.stage[storage.currentStage].val
			end
			refundTime = (growthDif / deltaGrowth) * secondsThisUpdate
			storage.lastWorldTime = storage.lastWorldTime - refundTime
			newGrowth = newGrowth - growthDif
		end
		storage.growth = newGrowth
	end
	
	--Check if we should try to use more fluid due to growth. (DON'T check the last stage)
	if storage.currentStage < storage.stages then
		if storage.growth >= storage.stage[storage.currentStage].val then
			storage.hasFluid = isn_doFluidConsume()
			storage.currentStage = storage.currentStage + 1
		end
	end
	
	--If the above fluid use left us dry stop here (don't output items) and try again later.
	--Yes this may generate 1 more (unnecessary) growth spurt but it won't use more fluid.
	if not storage.hasFluid then return end
	
	--Check if we are grown.
	if storage.growth >= storage.growthCap then
		--Spawn our output...
		for i = 1, storage.yield do
			--Generate the items.
			local itemDescriptors = nil
			if storage.hasTree then
				itemDescriptors = isn_genSaplingDrops()
			elseif root.isTreasurePool(storage.harvestPool) then
				itemDescriptors = root.createTreasure(storage.harvestPool, world.threatLevel())
			end
			--'Drop' the items.
			if type(itemDescriptors) == "table" then
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
--optional arg fluidNeed is amount of fluid required to top up to.
function isn_doWaterIntake(fluidNeed)
	local contents = world.containerItems(entity.id())
	local water = contents[storage.waterslot]
	if not water then return false end
	
	for key, value in pairs(config.getParameter("isn_waterInputs")) do
		if water.name == key and type(value) == "table" then
			local amount, boost = value[1], value[2]
			if type(amount) ~= "number" or amount <= 0 or type(boost) ~= "number" then
				sb.logWarning("[fu_growingtray] found valid fluid named %s however either amount (%s) or boost (%s) was invalid.", key, amount, boost)
				return false
			end
			local itemCount = (fluidNeed and math.min(water.count, math.ceil(fluidNeed / amount))) or 1
			storage.fluid = storage.fluid + (amount * itemCount)
			storage.growthFluid = boost
			world.containerConsume(entity.id(), {name = water.name, count = itemCount, data={}})
			return true
		end
	end
	return false
end

--Attempts to use up some fluid
function isn_doFluidConsume(multiplier)
	local useFluid = multiplier and storage.fluidUse * multiplier or storage.fluidUse
	if storage.fluid < useFluid then
		if not isn_doWaterIntake(useFluid - storage.fluid) then return false end
	end
	storage.fluid = storage.fluid - useFluid
	return true
end

--Fetch the seed from the storage slot, also does validity check.
function isn_readContainerSeed()
	local contents = world.containerItems(entity.id())
	local seed = contents[storage.seedslot]
	if not seed then return end
	--Verify the seed is valid for use.
	local seedConfig = root.itemConfig(seed).config
	if seedConfig.objectType ~= "farmable" then return nil end
	if seedConfig.objectName == "sapling" and not self.handlesSaplings then return nil end
	return seed
end

--Reads the currentseed's data.  Return false if there was a problem with the
--seed/data.
function isn_readSeedData()
	if not storage.currentseed then return false end
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
	while seedConfig.stages[index] do
		local curStage = seedConfig.stages[index]
		if type(curStage.duration) == "table" then
			storage.stages = index
			local stage = {}
			stage.min = curStage.duration[1] or 10
			stage.max = curStage.duration[2] or stage.min
			storage.stage[index] = stage
		else
			--We expect this branch to only happen once but just in case we use 'or'.
			storage.harvestPool = curStage.harvestPool or storage.harvestPool
			storage.resetStage = (curStage.resetToStage and curStage.resetToStage + 1) or storage.resetStage
			if curStage.tree then
				if not isn_readSaplingData() then return false end
				storage.harvestPool = ""
			end
		end
		index = index + 1
	end
	if index == 1 then return false end
	return true
end

--Reads sapling data and does minimal verification that we indeed have a valid
--sapling.
function isn_readSaplingData()
	if type(storage.currentseed.parameters) ~= "table" then return false end
	local stemType = storage.currentseed.parameters.stemName
	local foliageType = storage.currentseed.parameters.foliageName
	if not (stemType and foliageType) then return false end
	local stemPath = root.treeStemDirectory(stemType)
	local stemJson = root.assetJson(stemPath .. stemType .. ".modularstem")
	storage.stemDrops = stemJson.dropConfig.drops
	local foliagePath = root.treeFoliageDirectory(foliageType)
	local foliageJson = root.assetJson(foliagePath .. foliageType .. ".modularfoliage")
	storage.foliageDrops = foliageJson.dropConfig.drops
	storage.hasTree = true
	return true
end

--Generates drop data for a sapling
--[[
If I follow correctly, the stem and the foliage each can have a single item type drop.
That drop is randomly picked from "dropConfig/drops" table.
Equal weight, each drop line is a single item type and coresponding count.
Also foliage is the only source for saplings.
]]--
function isn_genSaplingDrops()
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
	if dropCount == 1 then return end
	return drops
end

--Generates growth data to tell when a plant is ready for harvest and when it
--needs to be watered.
function isn_genGrowthData(initStage)
	initStage = initStage or 1
	--Make sure some things make sense for a perennial, if not act like it's annual
	if initStage > storage.stages then
		initStage = 1
		storage.resetStage = 1
	end
	storage.currentStage = initStage
	storage.growthCap = 0
	local index = initStage
	while index <= storage.stages do
		local stage = storage.stage[index]
		if type(stage) ~= "table" then return false end
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
	if storage.hasTree then return isn_doSeedIntake() end
	
	local seed = isn_readContainerSeed()
	--If the seed in the seed slot isn't what's being grown now, re-init growth.
	if seed then
		if storage.currentseed.name ~= seed.name then
			--give the perennial seed back before swapping plants
			local itemCount = storage.seedUse or self.seedUse
			local descriptor = {name = storage.currentseed.name, count = itemCount, data={}}
			fu_sendOrStoreItems(0, descriptor, {0, 1, 2})
			return isn_doSeedIntake()
		end
	end
	--If the current plant isn't perennial, re-init growth.
	if storage.resetStage < 1 then
		return isn_doSeedIntake()
	end
	
	storage.growth = 0
	animator.setAnimationState("growth", "0")
	
	local oldSeedCount = storage.seedUse
	
	--set defaults that fertilizer can change or modify
	storage.growthRate = self.baseGPS
	storage.fluidUse = self.defaultFluidUse
	storage.seedUse = self.seedUse
	storage.yield = self.baseYield
	
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
	if not isn_genGrowthData() then
		storage.currentseed = nil
		storage.harvestPool = nil
		return false
	end
	--All state tests passed and we are ready to continue growing, consume some items.
	
	--Consume a unit of fertilizer.
	if fertName then
		world.containerConsume(entity.id(), {name = fertName, count = 1, data={}})
	end
	--Consume some fluid.
	storage.hasFluid = isn_doFluidConsume()
	
	return true
end

--Initialize plant activity (start from scratch)
function isn_doSeedIntake()
	storage.growth = 0
	animator.setAnimationState("growth", "0")
	storage.currentseed = nil
	storage.harvestPool = nil
	
	--Read/init seed data
	local seed = isn_readContainerSeed()
	if not seed then return false end
	storage.currentseed = seed
	if not isn_readSeedData() then
		storage.currentseed = nil
		return false 
	end
	
	--set defaults that fertilizer can change or modify
	storage.growthRate = self.baseGPS
	storage.fluidUse = self.defaultFluidUse
	storage.seedUse = self.seedUse
	storage.yield = self.baseYield
	
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
	if not isn_genGrowthData() then
		storage.currentseed = nil
		storage.harvestPool = nil
		return false
	end
	--All state tests passed and we are ready to grow, consume some items.
	
	--Consume a unit of fertilizer.
	if fertName then
		world.containerConsume(entity.id(), {name = fertName, count = 1, data={}})
	end
	--Consume some fluid.
	storage.hasFluid = isn_doFluidConsume()
	--Consume seed.
	world.containerConsume(entity.id(), {name = seed.name, count = storage.seedUse, data={}})
	
	return true
end

--Reads the current fertilizer slot and modifies growing state data based on
--what is found there.
--Returns nil if nothing to do, otherwise a string of the itemname to be used.
function isn_doFertProcess()
	local contents = world.containerItems(entity.id())
	local fert = contents[storage.fertslot]
	if not fert then return end
	storage.fluidUse = 1
	storage.growthFert = 0
	
	for key, value in pairs(config.getParameter("isn_fertInputs")) do
		if fert.name == key and type(value) == "table" then
			local seeds, use, boost, yield = value[1], value[2], value[3], value[4]
			if type(seeds) ~= "number" or seeds < 1 or type(use) ~= "number" or use <= 0 or
					type(boost) ~= "number" or type(yield) ~= number then
				sb.logWarning("[fu_growingtray] Found valid fertilizer named %s however one of the following are invalid:", key)
				sb.logWarning("                 use (%s), boost (%s), or yield (%s) was invalid.", seeds, use, boost, yield)
				return
			end
			storage.seedUse = seeds
			storage.fluidUse = use
			storage.growthFert = boost
			storage.yield = storage.yield + yield
			return fert.name
		end
	end
	return
end