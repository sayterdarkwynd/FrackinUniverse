
require "/scripts/util.lua"
require "/bees/genomeLibrary.lua"
require "/zb/zb_util.lua"
require "/scripts/kheAA/transferUtil.lua"


--[[		Comments:

--[[	Updating tooltips:

	You must "rebuild" the item.
	Just copy the items data, add the right tags, removing the original item, and readding the one with the tags
	Seems like only the builder has access to the tooltips
	Used this function to reveal a bees genome
--]]

--[[	Misc.

	Progress increases by the bees production stat multiplied by the hives production efficiency with a small random factor which applies for each product separetly
	Same applies to the queens production as well, but does not take drones into account
	Full formula:
	[D] = 1000 / Local drones in hive
	[H] = math.min(1 / ((1 + Hives around the hive) * 0.75), 1)
	[F] = Flower Favor
	[B] = Biome Favor (0 / 0.5 / 1 / 1.5)
	Production Multiplier = ([D] + [H] + [F] + [B]) / 4
	Production Stat * Production Multiplier * (math.random(90,110) * 0.01)

	Bee item image frames have a FFFFFF01 Hex colored pixels on the bottom left and top right of the frame because SB resizes the item image
--]]

--]]

queen = nil			-- Contains the queen or nil if there's no queen
hivesAroundHive = 0		-- Active hives around the hive
delayedInit = true		-- Used to delay some things initialization due to how some SBs functions work
biome = nil			-- The world type/biome
beeTickDelta = 0		-- Variable holding delta between bee ticks.
noQueenTimer = 0		-- Time left before drones start dying without a queen
noQueenTimeAllowed = 60		-- Time before drones start dying without a queen

-- Whether the hive has a frame, and the bonus stats it provides
hasFrame = false
frameBonuses = {
	baseProduction = 0,
	droneToughness = 0,
	droneBreedRate = 0,
	queenBreedRate = 0,
	queenLifespan = 0,
	mutationChance = 0,
	miteResistance = 0,
	allowDay = false,
	allowNight = false,
	heatResistance = false,
	coldResistance = false,
	radResistance = false,
	cosmicResistance = false,
	physicalResistance = false
}

-- Table storing functions called by unique frames every bee tick
-- Which function the frame should call (if at all) is determined within the frames config under 'specialFunction'
-- Passes 'functionParams' from within the config to the function
specialFrameFunctions = {
--	Note: These functions are only called once per frame referencing the function every bee tick.
--	Note: They also don't take into account bee activity, so check for bees as required:
--		isHiveQueenActive(true) - will return if the queen is active
--		areDronesActive() - will return if at least one instance of drones is active
--	Tip: Use 'beeTickDelta' to get delta between bee ticks.

	advancedFrame = function(data)
		if not advancedFrameTimer then
			advancedFrameTimer = data[1]
		elseif advancedFrameTimer <= 0 then
			--sb.logInfo(data[2])
			advancedFrameTimer = data[1]
		else
			advancedFrameTimer = advancedFrameTimer - beeTickDelta
		end
	end,
	antimiteFrame = function(data)
		self.randAmount = math.random(1,8)
		if isHiveQueenActive(true) and areDronesActive() then
			if not antimiteFrameTimer then
				antimiteFrameTimer = data[1]
			elseif antimiteFrameTimer <= 0 then
				antimiteFrameTimer = math.random(100,540)
			else
				antimiteFrameTimer = antimiteFrameTimer - beeTickDelta
			end
		end
	end,
	copperFrame = function(data)
	        self.randAmount = math.random(1,2)
		if isHiveQueenActive(true) and areDronesActive() then
			if not ironFrameTimer then
				ironFrameTimer = data[1]
			elseif ironFrameTimer <= 0 then
				world.spawnItem("copperore",entity.position(),self.randAmount)
				ironFrameTimer = math.random(100,540)
			else
				ironFrameTimer = ironFrameTimer - beeTickDelta
			end
		end
	end,
	ironFrame = function(data)
	        self.randAmount = math.random(1,2)
		if isHiveQueenActive(true) and areDronesActive() then
			if not ironFrameTimer then
				ironFrameTimer = data[1]
			elseif ironFrameTimer <= 0 then
				world.spawnItem("ironore",entity.position(),self.randAmount)
				ironFrameTimer = math.random(100,540)
			else
				ironFrameTimer = ironFrameTimer - beeTickDelta
			end
		end
	end,
	tungstenFrame = function(data)
	        self.randAmount = math.random(1,2)
		if isHiveQueenActive(true) and areDronesActive() then
			if not ironFrameTimer then
				ironFrameTimer = data[1]
			elseif ironFrameTimer <= 0 then
				world.spawnItem("tungstenore",entity.position(),self.randAmount)
				ironFrameTimer = math.random(100,540)
			else
				ironFrameTimer = ironFrameTimer - beeTickDelta
			end
		end
	end,
	titaniumFrame = function(data)
	        self.randAmount = math.random(1,2)
		if isHiveQueenActive(true) and areDronesActive() then
			if not ironFrameTimer then
				ironFrameTimer = data[1]
			elseif ironFrameTimer <= 0 then
				world.spawnItem("titaniumore",entity.position(),self.randAmount)
				ironFrameTimer = math.random(100,540)
			else
				ironFrameTimer = ironFrameTimer - beeTickDelta
			end
		end
	end,
	durasteelFrame = function(data)
	        self.randAmount = math.random(1,2)
		if isHiveQueenActive(true) and areDronesActive() then
			if not ironFrameTimer then
				ironFrameTimer = data[1]
			elseif ironFrameTimer <= 0 then
				world.spawnItem("durasteelore",entity.position(),self.randAmount)
				ironFrameTimer = math.random(100,540)
			else
				ironFrameTimer = ironFrameTimer - beeTickDelta
			end
		end
	end

}

-- Variables responsible for holding old animation states to prevent restarting animations
oldBaseState = nil
oldBeeState = nil
oldLoadingState = nil

-- Method to differentiate between apiaries and other objects
function getClass() return "apiary" end

-- Begin script
function init()
	biome = world.type()

	-- Disabled on ship and player space stations
	if biome == "unknown" then   --or biome == "playerstation" then
		script.setUpdateDelta(-1)
		return
	end

	-- Retrieve data
	maxStackDefault = root.assetJson("/items/defaultParameters.config").defaultMaxStack
	beeData = root.assetJson("/bees/beeData.config")
	slotCount = config.getParameter("slotCount")
	queenSlot = config.getParameter("queenSlot")
	droneSlots = config.getParameter("droneSlots")
	frameSlots = config.getParameter("frameSlots")
	firstInventorySlot = config.getParameter("firstInventorySlot")

	-- Get contents now because its needed in some functions which may get called before the first bee update tick
	contents = world.containerItems(entity.id())

	-- Init drone production table. Not in storage because it should reset every init
	droneProductionProgress = {}

	-- Init young queen and drone breeding progress
	youngQueenProgress = 0
	droneProgress = 0

	-- Init mite counter
	storage.mites = storage.mites or 0

	-- Init loading animation
	setAnimationStates(true, false, false)

	-- Init timer, and offset update delta to reduce potential lag spikes when they all update at the same time
	beeUpdateTimer = beeData.beeUpdateInterval



	local timerIncrement = config.getParameter("scriptDelta") * 0.01

	local sameTimers
	repeat
		beeUpdateTimer = beeUpdateTimer + timerIncrement
		sameTimers = world.objectQuery(entity.position(), 10, {withoutEntityId = entity.id(), callScript = "GetUpdateTimer", callScriptResult = beeUpdateTimer})
	until (not sameTimers or #sameTimers == 0)
end

-- First update, used to do some things we don't need every update. Switches to update2 when its not needed anymore
function update(dt)
	-- Doing this here because if the object initializes with the planet, world.time() returns 0
	if not ticksToSimulate then
		-- Get amount of ticks the apiary should simulate. (off-screen production simulation)
		if storage.lastActive then
			setAnimationStates(false, false, true)
			object.setInteractive(false)
			ticksToSimulate = beeData and beeData.unloadedUpdateInterval and (storage.unfinishedTicks or 0) + math.floor((world.time() - storage.lastActive) / beeData.unloadedUpdateInterval) or 0
			storage.unfinishedTicks = nil
		else
			object.setInteractive(true)
			update = update2
		end

	else
		if ticksToSimulate > 0 then
			-- Simulate bee ticks if needed. Hive is paused and cannot be interacted with while it does that.
			local ticks = math.min(ticksToSimulate, beeData.maxSimulatedTicksPerUpdate)
			ticksToSimulate = ticksToSimulate - ticks

			for _ = 1, ticks do
				beeTick(dt)
			end
		else
			-- Renable interaction if done simulating ticks
			setAnimationStates(true, false, false)
			ticksToSimulate = nil
			object.setInteractive(true)
			update = update2
		end
	end
end

-- Called as update when the first update is done
function update2(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
	beeUpdateTimer = beeUpdateTimer - dt
	beeTickDelta = beeTickDelta + dt

	if beeUpdateTimer <= 0 then
		beeUpdateTimer = beeData.beeUpdateInterval
		beeTick(beeData.beeUpdateInterval)
		beeTickDelta = 0
	end
end

-- Called when the object is broken.
function die()
	-- Made object not drop itself upon breaking to handle it through here so mites remain.
	if storage.mites and storage.mites > 0 then
		local icon = config.getParameter("inventoryIcon").."?border=1;FF0000?fade=007800;0.1"
		world.spawnItem(object.name(), entity.position(), 1, {mites = storage.mites, inventoryIcon = icon})
	else
		world.spawnItem(object.name(), entity.position(), 1)
	end
end

-- Called when the object is unloaded.
function uninit()
	storage.unfinishedTicks = ticksToSimulate
	storage.lastActive = world.time()
end

-- Bee ticks that should happen while the object is not loaded
-- Called on init if there are any ticks that need simulating
-- While just calling update a bunch of times in a row is easy, it has a lot of stuff going on that you don't need
function beeTick(dt)
	contents = world.containerItems(entity.id())

	-- Get amount of hives with active drones in the areas
	-- NOTE TO SELF: Can call functions inside other objects in a synced manner using this method:
	local hives = world.objectQuery(entity.position(), 10, {withoutEntityId = entity.id(), callScript = "areDronesActive", callScriptResult = true})
	hivesAroundHive = #hives

	-- Production should be halted if theres a rivalry inside the hive
	local haltProduction = checkRivalries()

	-- Check if there's a frame and get their bonuses
	getFrames(dt)

	-- Check if there was a queen in the queen slot last time the object updated
	if queen then
		-- If last update had a queen, see if the item currently placed in the queen slot is a queen
		-- If it is, compare indexed and in slot queens genetic code and age, because those are the only differences queens can have
		-- If its not, clear the index, marking the hive as queenless, and init the noQueenTimer
		if contents[queenSlot] and root.itemHasTag(contents[queenSlot].name, "bee") then
			if root.itemHasTag(contents[queenSlot].name, "queen") then
				sameStats,sameAge=isSameQueen(queen, contents[queenSlot])--returns sameQueen only if sameStats is true
				if sameStats then
					if not sameAge then
						queen = contents[queenSlot]	-- If its not identical, replace indexed queen with the one in the slot
					end
					if isHiveQueenActive() and hasDrones and not haltProduction then
						queenProduction() -- Progress queen production if its the same queen, and she's active, and there are drones in the hive (doesn't matter if they're active)
					end
				else
					queen = contents[queenSlot]	-- If its not identical, replace indexed queen with the one in the slot
					youngQueenProgress = 0		-- And reset queen production progress
					droneProgress = 0
				end
			elseif root.itemHasTag(contents[queenSlot].name, "youngQueen") then
				-- If the slot has a young queen, convert it into a normal queen and reset queen production progress
				youngQueenProgress = 0
				droneProgress = 0

				queen = youngQueenToQueen(contents[queenSlot])
				world.containerTakeAt(entity.id(), queenSlot-1)
				world.containerPutItemsAt(entity.id(), queen, queenSlot-1)
				contents[queenSlot] = world.containerItemAt(entity.id(), queenSlot-1)
			else
				noQueenTimer = noQueenTimeAllowed
				queen = nil
			end
		else
			-- Mark hive as queenless and init noQueenTimer
			noQueenTimer = noQueenTimeAllowed
			queen = nil
		end
	else
		-- If last update didn't have a queen and there's an item in the queen slot
		if contents[queenSlot] and root.itemHasTag(contents[queenSlot].name, "bee") then
			if root.itemHasTag(contents[queenSlot].name, "queen") then
				-- Index it if its a queen bee. Give it a genome if it doesn't have one

				queen = contents[queenSlot]
				if not queen.parameters.genome then
					queen.parameters.genome = genelib.generateDefaultGenome(queen.name)
					world.containerTakeAt(entity.id(), queenSlot-1)
					world.containerPutItemsAt(entity.id(), queen, queenSlot-1)
					contents[queenSlot] = world.containerItemAt(entity.id(), queenSlot-1)
				end

			elseif root.itemHasTag(contents[queenSlot].name, "youngQueen") then
				-- Convert to a queen and index it if its a young queen
				queen = youngQueenToQueen(contents[queenSlot])
				world.containerTakeAt(entity.id(), queenSlot-1)
				world.containerPutItemsAt(entity.id(), queen, queenSlot-1)
				contents[queenSlot] = world.containerItemAt(entity.id(), queenSlot-1)
			end
		end
	end

	-- Check if the items in the slots are actually drones, get them attacked by mites, and progress production if they're currently active
	-- Also, if a wild queen is present, make all wild drones of the same family have the same genome
	-- And reveal the drones genome if it matches the queens
	hasDrones = false
	for _, slot in ipairs(droneSlots) do
		local item = contents[slot]
		if item and root.itemHasTag(item.name, "bee") and root.itemHasTag(item.name, "drone") then

			-- If theres a wild queen, the drone is wild, and they're both of the same family, set the drones genome to the queens
			-- If the drones are not the queens offsprings, decay them
			if queen then
				if family(queen.name) == family(item.name) then
					local readd = false

					if queen.parameters.wild then
						readd = true
						item.parameters.genome = queen.parameters.genome
					end

					if queen.parameters.genome == item.parameters.genome then
						readd = true
						item.parameters.genomeInspected = queen.parameters.genomeInspected
					else
						droneDecay(slot)
					end

					if readd then
						world.containerTakeAt(entity.id(), slot-1)
						world.containerPutItemsAt(entity.id(), item, slot-1)
						contents[slot] = world.containerItemAt(entity.id(), slot-1)
					end
				--else
					--droneDecay(slot)
				end
			else
				-- Kill drones if there's no queen present, and the no queen timer ran out
				if noQueenTimer <= 0 then
					droneDecay(slot)
				end
			end

			-- Kill drones if there are mites present
			if storage.mites > 0 and contents[slot] then
				miteDamage(slot)
				item = contents[slot]
			end

			-- Check if there are drones remaining after the mite attack
			if item then
				hasDrones = true

				-- Get if this specific instance of drones is active
				if not haltProduction and isDroneActive(item) then
					droneProduction(item)
				end
			end
		end
	end

	-- Mites reproduce only if there are drones in the hive
	-- Kill the queen if there are mites but no drones
	if hasDrones then
		miteGrowth()

		-- Decay the no queen timer if there's no queen but drones are present
		if not queen and noQueenTimer > 0 then
			noQueenTimer = noQueenTimer - beeTickDelta
		end
	else
		noQueenTimer = noQueenTimeAllowed
		if storage.mites > 0 and queen then
			world.containerTakeAt(entity.id(), queenSlot-1)
			queen = nil
		end
	end

	-- If simulated ticks, check whether there are still bees to be simulated, and stop simulating if there are none
	-- Otherwise change animation state according to hive activity
	if ticksToSimulate then
		if not hasDrones and not queen then
			ticksToSimulate = 0
		end
	else
		if haltProduction or not areDronesActive() then
			setAnimationStates(true, false, false)
		else
			setAnimationStates(true, true, false)
		end
	end
end

-- Check for frames, and get the stat modifiers
function getFrames(dt)

	-- Set default values
	hasFrame = false
	frameBonuses = {
		baseProduction = 0,
		droneToughness = 0,
		droneBreedRate = 0,
		queenBreedRate = 0,
		queenLifespan = 0,
		mutationChance = 0,
		miteResistance = 0,
		allowDay = false,
		allowNight = false,
		heatResistance = false,
		coldResistance = false,
		radResistance = false,
		cosmicResistance = false,
		physicalResistance = false
	}
	if not self.frameTakeTimers then
--		sb.logInfo("initializing frame grab timers")
		self.frameTakeTimers={}
	end
	local frameCounter=0
	-- Iterate through frame slots, set 'hasFrame' to true if there's a frame, and add bonuses to the table
	-- Also call their special function from the 'specialFrameFunctions' table if they have one
	for _, frameSlot in ipairs(frameSlots) do
		if contents[frameSlot] and root.itemHasTag(contents[frameSlot].name, "apiaryFrame") then
			frameCounter=frameCounter+1
			hasFrame = true
			local cfg = root.itemConfig(contents[frameSlot].name)
			--local amountcheck = contents[frameSlot].count--currently unused

			for stat, _ in pairs(frameBonuses) do--value in pairs(frameBonuses) do
				if stat == "allowDay" or stat == "allowNight" or stat== "frameWorktimeModifierDay" or stat=="frameWorktimeModifierNight" or stat == "coldResistance" or stat=="heatResistance" or stat=="radResistance" or stat=="physicalResistance" or stat=="cosmicResistance" then
					if cfg.config[stat] then
						frameBonuses[stat] = true
					end
				elseif cfg.config[stat] then
				        -- the total frame count influences the overall stats. Take the current frame bonus and add the amount in the stack to the provided bonus
					frameBonuses[stat] = (frameBonuses[stat] + cfg.config[stat]) * (1 + ((contents[frameSlot].count/100) * 0.5 )) --add total frames to total
				end
			end

			if specialFrameFunctions[cfg.config.specialFunction] then
				specialFrameFunctions[cfg.config.specialFunction](cfg.config.functionParams)
			end

			-- we remove frames randomly based on a rare diceroll. all frames use the same rate. This keeps stacks replenishing via crafting rather than a one-time bit of crafting
			self.frameTakeTimers[frameCounter]=(self.frameTakeTimers[frameCounter] or 0) + (dt or 0)
			if self.frameTakeTimers[frameCounter] >= 180.0 and hasDrone and queen then
				local randomChanceToTake = math.random(50)
				if randomChanceToTake == 1 then
					world.containerTakeNumItemsAt(entity.id(), frameSlot-1, 1)
					contents[frameSlot] = world.containerItemAt(entity.id(), frameSlot-1)
				end
				self.frameTakeTimers[frameCounter]=0.0
			end				
		end
	end
	--not including, it'd be too easy to cheese
	--[[while #self.frameTakeTimers>frameCounter do
		self.frameTakeTimers[frameCounter+1]=nil
	end]]
end


-- Function used by external sources to get current time remaining until next bee production
function GetUpdateTimer() return beeUpdateTimer end

-- Check if the two passed queens are the same
function isSameQueen(q1, q2)
	if q1.name == q2.name then
		q1 = q1.parameters
		q2 = q2.parameters

		if 	q1.genome == q2.genome
			and q1.age == q2.age
			and q1.hatedPlants == q2.hatedPlants
			and q1.dislikedPlants == q2.dislikedPlants
			and q1.favoritePlants == q2.favoritePlants
			and q1.deadlyBiomes == q2.deadlyBiomes
			and q1.hatedBiomes == q2.hatedBiomes
			and q1.favoriteBiomes == q2.favoriteBiomes then
			return true, (q1.lifespan == q2.lifespan)
		end
	end
	return false
end

-- Checks the queens activity status. Can be called via external sources to get it.
function isHiveQueenActive(externalCall)
	-- Just return the variable if its an external call
	if externalCall then return hiveQueenActive end

	-- no queen = no active queen. Yes, I've done several hours of research to make sure this is indeed correct.
	if not queen then
		hiveQueenActive = false
		return false
	end

	-- No frames = no activity
	if not hasFrame then
		hiveQueenActive = false
		return false
	end

	-- Always active for simulated ticks. Whether anything actually happens is determined within the production function
	if ticksToSimulate then
		hiveQueenActive = true
		return true
	end

	-- Get worktime, and check if the queen should be active during this time. Include frame effects.
	local workTime = genelib.statFromGenomeToValue(queen.parameters.genome, "workTime")
	local timeOfDay = world.timeOfDay()

	if workTime == "both" then
		hiveQueenActive = true
		return true

	elseif timeOfDay <= 0.5 then
		if workTime == "day" or frameBonuses.allowDay then
			hiveQueenActive = true
			return true
		end

	else
		if workTime == "night" or frameBonuses.allowNight then
			hiveQueenActive = true
			return true
		end
	end

	hiveQueenActive = false
	return false
end

-- Progress queens production
function queenProduction()
	-- Get biome favor. Do nothing else if its considered deadly for the bee.
	local biomeFavor = getBiomeFavor(queen.name)
	if biomeFavor == -1 then return end

	-- Get flower favor. Do nothing else if the flower requirements are not met.
	local family = family(queen.name)
	local subtypeID = genelib.statFromGenomeToValue(queen.parameters.genome, "subtype")
	local flowerFavor = getFlowerLikeness(beeData.stats[family][subtypeID].name)
	if flowerFavor == -1 then return end

	-- If simulating ticks, ignore every odd tick
	if ticksToSimulate and ticksToSimulate % 2 == 1 and genelib.statFromGenomeToValue(queen.parameters.genome, "workTime") ~= "both" then
		return
	end

	if not ticksToSimulate then tryBeeSpawn(family, queen.parameters.genome) end

	-- Queen production is unaffected by hives around hive
	local productionDrone = genelib.statFromGenomeToValue(queen.parameters.genome, "droneBreedRate") + frameBonuses.droneBreedRate * ((flowerFavor + biomeFavor) / 2)
	-- below, a base value of 0.01 was added so that even 0 Queen Breed bees have a low chance
	local productionQueen = 0.01 + genelib.statFromGenomeToValue(queen.parameters.genome, "queenBreedRate") + frameBonuses.queenBreedRate * ((flowerFavor + biomeFavor) / 2)

	-- adjusted to 50% instead of 25% on 11-04-2020
	-- also added a divider to the droneProgress so drone births are 75% less frequent. This will lower production rates as a consequence as bees breed.
	--youngQueenProgress = youngQueenProgress + productionQueen * (math.random(beeData.productionRandomModifierRange[1],beeData.productionRandomModifierRange[2]) * 0.01) * 0.25
	youngQueenProgress = youngQueenProgress + productionQueen * (math.random(beeData.productionRandomModifierRange[1],beeData.productionRandomModifierRange[2]) * 0.01) * 0.5
	--sb.logInfo(youngQueenProgress)
	droneProgress = droneProgress + productionDrone * (math.random(beeData.productionRandomModifierRange[1],beeData.productionRandomModifierRange[2]) * 0.01)  * 0.25

	if youngQueenProgress >= beeData.youngQueenProductionRequirement then
		local produced = math.floor(youngQueenProgress / beeData.youngQueenProductionRequirement)
		youngQueenProgress = youngQueenProgress % beeData.youngQueenProductionRequirement

		for i = 1, produced do--for _ = 1, math.floor(youngQueenProgress / beeData.youngQueenProductionRequirement) do--produced do
			local youngQueen = generateYoungQueen() -- Generate queen stats
			for j = firstInventorySlot, slotCount do
				youngQueen = world.containerPutItemsAt(entity.id(), youngQueen, j-1)
				contents[j] = world.containerItemAt(entity.id(), j-1)
				if not youngQueen then break end
			end
			-- Do nothing if there's no room for a young queen in the apiaries inventory
		end
	end

	if droneProgress >= beeData.droneProductionRequirement then
		local produced = math.floor(droneProgress / beeData.droneProductionRequirement)
		droneProgress = droneProgress % beeData.droneProductionRequirement

		-- Create the drone item based on the queens name, and copy her genome
		local params = copy(queen.parameters)
		params.lifespan = nil
		local drones = {name = "bee_"..family.."_drone", count = produced, parameters = params}

		-- Find queens offspring drones and increment them if they're present
		for _, droneSlot in ipairs(droneSlots) do
			local slotItem = world.containerItemAt(entity.id(), droneSlot-1)

			if slotItem and compare(slotItem.parameters, drones.parameters) then
				world.containerPutItemsAt(entity.id(), drones, droneSlot-1)
				contents[droneSlot] = world.containerItemAt(entity.id(), droneSlot-1)
				ageQueen()
				return
			end
		end

		-- Otherwise, add them to the first empty slot.
		for _, droneSlot in ipairs(droneSlots) do
			local slotItem = world.containerItemAt(entity.id(), droneSlot-1)
			if not slotItem then
				world.containerPutItemsAt(entity.id(), drones, droneSlot-1)
				contents[droneSlot] = world.containerItemAt(entity.id(), droneSlot-1)
				ageQueen()
				return
			end
		end

		-- If there are no free drone slots, iterate through the inventory and find a stack of this drone
		-- Do nothing if there is 1000 or more drones of this type in the apiaries inventory
		local droneSlot = nil
		local totalDrones = 0
		for i = firstInventorySlot, slotCount do
			if contents[i] and contents[i].name == drones.name and compare(contents[i].parameters, drones.parameters) then
				totalDrones = totalDrones + contents[i].count

				if totalDrones >= 1000 then
					ageQueen()
					return
				end

				droneSlot = i
			end
		end
		-- If a slot with this type of drones was found, stack em into the inventory, Otherwise just add it to the inventory
		if droneSlot then
			world.containerStackItems(entity.id(), drones)
		else
			world.containerAddItems(entity.id(), drones)
		end
	end
	-- Will not always reach here because of how I wrote the drone adding segment
	ageQueen()
end

-- Reduce queens lifespan by 1 each queens production and remove the item if it reaches 0, or re-add it to update the value on the item in storage
-- By default ages the queen by 1, but can use any other number or negative ones to make her last longer
-- Can be called from other places (Like the frame scripts)
function ageQueen(amount)
	--if changing this, make sure it matches in beeBuilder.lua
    local fullLifespan = genelib.statFromGenomeToValue(queen.parameters.genome, "queenLifespan") * ((frameBonuses.queenLifespan or 0 / 8) + 1)
    --sb.logInfo(fullLifespan)

	if not queen.parameters.lifespan or queen.parameters.lifespan < 0 then
	  queen.parameters.lifespan = fullLifespan
	end


	queen.parameters.lifespan = queen.parameters.lifespan - (amount or 1)
	world.containerTakeAt(entity.id(), queenSlot-1)

	if (queen.parameters.lifespan > 0) then
		world.containerPutItemsAt(entity.id(), queen, queenSlot-1)
	else
		contents[queenSlot] = nil
		queen = nil
	end
end

-- Generates and returns a young queen item descriptor
function generateYoungQueen()
	local descriptor = {}

	local underscore1 = string.find(queen.name, "_")
	local underscore2 = string.find(queen.name, "_", underscore1+1)
	descriptor.name = "bee_"..string.sub(queen.name, underscore1+1, underscore2-1).."_youngQueen"

	local genomeTable = {}
	for _, slot in ipairs(droneSlots) do
		if contents[slot] and root.itemHasTag(contents[slot].name, "drone") then
			table.insert(genomeTable, contents[slot].parameters.genome)
		end
	end

	local newGenome = genelib.getAvarageGenome(queen.parameters.genome, genomeTable)
	newGenome = genelib.evolveGenome(newGenome, frameBonuses.mutationChance)

	descriptor.parameters = {genome = newGenome}
	return descriptor
end

-- Function for randomizing a stat value for when a new queen is generated--totally unused
--[[function randomMod(num)
	local rnd = math.random()

	if rnd <= 0.05 then -- 5% -3
		num = num - 3
	elseif rnd <= 0.15 then -- 10% -2
		num = num - 2
	elseif rnd <= 0.30 then -- 15% -1
		num = num - 1
	elseif rnd <= 0.70 then -- 40% 0
		-- Do nothing
	elseif rnd <= 0.85 then -- 15% +1
		num = num + 1
	elseif rnd <= 0.95 then -- 10% +2
		num = num + 2
	else-- rnd <= 1.00 -- 5% +3
		num = num + 3
	end

	return num
end]]

-- Returns a queen version of the young queen, with exactly the same stats and parameters
function youngQueenToQueen(youngQueen)
	local newQueen = root.createItem(string.gsub(youngQueen.name, "youngQueen", "queen"))
	newQueen.parameters = copy(youngQueen.parameters)
	return newQueen
end

-- Kill drones based on their amount when no queen is present
function droneDecay(slot)
	self.chanceRemove = math.random(100) --remove chance of drones
	local amount = contents[slot].count -- set the amount
	if self.chanceRemove > 75 then--25% chance of removal
		world.containerTakeNumItemsAt(entity.id(), slot-1, math.floor(amount * beeData.droneDecayPercentile + beeData.droneDecayFlat))
		contents[slot] = world.containerItemAt(entity.id(), slot-1)
	end	
end

-- Receives a slot and reduces the amount of drones there based on the drones mite resistance stat and the amount of mites
function miteDamage(slot)
	-- Having this be 0 will instantly kill all drones as soon as a mite is added
	local toughness = math.max(genelib.statFromGenomeToValue(contents[slot].parameters.genome, "droneToughness") + frameBonuses.droneToughness, 1)

	world.containerTakeNumItemsAt(entity.id(), slot-1, math.floor(storage.mites / toughness))
	contents[slot] = world.containerItemAt(entity.id(), slot-1)
end

-- Checks if the passed drone is active
function isDroneActive(drone)

	-- No frames = no activity
	if not hasFrame or not queen then
		return false
	end

	-- Always active for simulated ticks. Whether anything actually happens is determined within the production function
	if ticksToSimulate then return true end

	-- Get the worktime stat, and check if the drones should be active, taking work time modifying frames into account
	local workTime = genelib.statFromGenomeToValue(drone.parameters.genome, "workTime")
	local timeOfDay = world.timeOfDay()

	if workTime == "both" then
		return true

	elseif timeOfDay <= 0.5 then
		if workTime == "day" or frameBonuses.allowDay then
			return true
		end

	else
		if workTime == "night" or frameBonuses.allowNight then
			return true
		end
	end

	return false
end

-- Function to check if the hive has any currently active drones. Used by other apiary instances to determine their own drone efficiency.
function areDronesActive()
	-- Return false if the object haven't even inited
	if not contents then return false end

	for _, slot in ipairs(droneSlots) do
		local item = contents[slot]
		if item and root.itemHasTag(item.name, "bee") and root.itemHasTag(item.name, "drone") then
			if isDroneActive(item) then
				return true
			end
		end
	end

	return false
end

-- Progress drones production based on the drone received
function droneProduction(drone)

	-- Get biome favor. Do nothing else if its considered deadly for the bee.
	local biomeFavor = getBiomeFavor(drone.name)
	if biomeFavor == -1 then return end

	-- Get flower favor. Do nothing else if the flower requirements are not met.
	local family = family(drone.name)
	local subtypeID = genelib.statFromGenomeToValue(drone.parameters.genome, "subtype")
	local flowerFavor = getFlowerLikeness(beeData.stats[family][subtypeID].name)
	if flowerFavor == -1 then return end

	-- If simulating ticks, ignore every odd tick
	if ticksToSimulate and ticksToSimulate % 2 == 1 and genelib.statFromGenomeToValue(drone.parameters.genome, "workTime") ~= "both" then
		return
	end

	local productionStat = genelib.statFromGenomeToValue(drone.parameters.genome, "baseProduction") + frameBonuses.baseProduction
	local production = productionStat * (((drone.count / 1000) + math.min(1 / ((1 + hivesAroundHive) * 0.75), 1) + flowerFavor + biomeFavor) / 4) * 0.5
	--sb.logInfo(production)
	for product, requirement in pairs(beeData.stats[family][subtypeID].production) do
		if not droneProductionProgress[product] then
			droneProductionProgress[product] = production
		else
			droneProductionProgress[product] = droneProductionProgress[product] + production
		end

		if droneProductionProgress[product] >= requirement then
			local item = {name = product, count = math.floor(droneProductionProgress[product] / requirement)}
			droneProductionProgress[product] = droneProductionProgress[product] - (requirement * item.count)

			for i = firstInventorySlot, slotCount do
				-- Not using "world.containerAddItems" because it would consider the queen, drone, and frame slots
				item = world.containerPutItemsAt(entity.id(), item, i-1)
				contents[i] = world.containerItemAt(entity.id(), i-1)
				if not item then break end
			end

			-- Drop items if there is no inventory space and the ticks aren't simulted
			if item and not ticksToSimulate then
				world.spawnItem(item, entity.position(), nil, nil, nil, 0.5)
			end
		end
	end
end

-- Roll for mite infestation, or increment mite count if there's an infestation
function miteGrowth()
	if storage.mites > 0 then

	        --display an infested hive image over the normal hive appearance if its infested enough
		if storage.mites > 50 then  --if mites pass 100, display a rotten looking apiary
		  animator.setAnimationState("base", "infested", true)
		  animator.setAnimationState("warning", "on", true)
		elseif storage.mites > 200 then  --if mites pass 200, display a really rotten looking apiary
		  animator.setAnimationState("base", "infested2", true)
		  animator.setAnimationState("warning", "on", true)
		else
		  animator.setAnimationState("base", "default", true)
		  animator.setAnimationState("warning", "off", true)
		end

		-- The growth multiplier. responsible for increasing mites by [current amount of mites] * this value
		local mult = beeData.mites.growthPercentile

		-- Get the hives total mite resistance (all drone resistances / number of drones occupying drone slots)
		local hiveMiteResistance = 0
		local droneCount = 0

		for _, slot in ipairs(droneSlots) do
			local item = contents[slot]
			if item and root.itemHasTag(item.name, "bee") and root.itemHasTag(item.name, "drone") then
				hiveMiteResistance = hiveMiteResistance + genelib.statFromGenomeToValue(item.parameters.genome, "miteResistance") + frameBonuses.miteResistance
				droneCount = droneCount + 1
			end
		end

		-- miteResistance stat range at the time of writing this: -6.475 to 6.475
		-- If the value is positive, the hive is resistant to mites, and the multiplier is reduced to [mult]/([stat]*100), can't be lower than 0.0001
		-- If the value is negative, the hive is weaker to mites, and the multiplier is multiplied by the stat (a non-negative version of it that is)
		if droneCount > 0 then
			hiveMiteResistance = hiveMiteResistance / droneCount

			-- we create a little function that improves as resistance does
			if hiveMiteResistance > 0 then
				mult = math.max(mult / (hiveMiteResistance*100), beeData.mites.growthPercentileMinimum)
			elseif hiveMiteResistance < 0 then
				mult = mult + mult * math.abs(hiveMiteResistance)
			end
		end

		-- remove the hive resistance from the mite total if over a certain threshold, otherwise increment them
		if hiveMiteResistance > 0 then
		  storage.mites = storage.mites - (hiveMiteResistance)
		else
	          storage.mites = storage.mites + (storage.mites * mult) + beeData.mites.growthStatic
		end

	elseif math.random() <= beeData.mites.infestationChance then
	    storage.mites = beeData.mites.growthStatic
	end
end

-- Check for rivalries within the hive
-- If a rivalry is detected, dwindle all drone numbers based on their toughness, and return true
function checkRivalries()
	if #droneSlots < 2 then return false end

	local haltProduction = false
	for i, slot in ipairs(droneSlots) do
		if i < #droneSlots then
			local item1 = contents[slot]
			local item2 = contents[droneSlots[i+1]]

			if item1 and item2 then
				if root.itemHasTag(item1.name, "drone") and root.itemHasTag(item2.name, "drone") then
					if areRivals(item1.name, item2.name) then
						haltProduction = true
						droneFight(slot, droneSlots[i+1])
					end
				end
			end
		end
	end

	return haltProduction
end

-- Make bees fight each other, dwindling each sides numbers based on drones in stack and their toughness stat
function droneFight(slot1, slot2)
	local bee1 = contents[slot1]
	local bee2 = contents[slot2]

	-- Not including frame bonus here because its redundant
	local tough1 = genelib.statFromGenomeToValue(bee1.parameters.genome, "droneToughness")
	local tough2 = genelib.statFromGenomeToValue(bee2.parameters.genome, "droneToughness")

	local totalHealth1 = bee1.count * tough1
	local totalHealth2 = bee2.count * tough2

	local newCount1 = math.floor((totalHealth1 - (totalHealth2 / 3)) / tough1)
	local newCount2 = math.floor((totalHealth2 - (totalHealth1 / 3)) / tough2)

	world.containerTakeNumItemsAt(entity.id(), slot1-1, bee1.count - newCount1)
	world.containerTakeNumItemsAt(entity.id(), slot2-1, bee2.count - newCount2)

	contents[slot1] = world.containerItemAt(entity.id(), slot1-1)
	contents[slot2] = world.containerItemAt(entity.id(), slot2-1)
end

-- Check if the two passed bee families are rivals
function areRivals(name1, name2)
	-- Return false if the bees are of the same family
	if name1 == name2 then return false end

	--sb.logInfo("names: %s",{name1,name2})
	if string.find(name1, "_") then
		name1 = family(name1)
	end

	if string.find(name2, "_") then
		name2 = family(name2)
	end
	--sb.logInfo("families: %s",{name1,name2})
	-- Check if the first bee is the rival for the second
	if type(beeData.rivals[name1]) == "string" then
		if beeData.rivals[name1] == name2 then
			return true
		end
	elseif type(beeData.rivals[name1]) == "table" then
		for _, rival in ipairs(beeData.rivals[name1]) do
			if name2 == rival then
				return true
			end
		end
	end

	-- Check if the second bee is the rival to the first
	if type(beeData.rivals[name2]) == "string" then
		if beeData.rivals[name2] == name1 then
			return true
		end
	elseif type(beeData.rivals[name2]) == "table" then
		for _, rival in ipairs(beeData.rivals[name2]) do
			if name1 == rival then
				return true
			end
		end
	end

	return false
end

-- Extract family name from the item name
function family(name)
	local underscore1 = string.find(name, "_")
	local underscore2 = string.find(name, "_", underscore1+1)
	return string.sub(name, underscore1+1, underscore2-1)
end

-- Returns the production modifier from the biome, or -1 if the biome is deadly
function getBiomeFavor(name)
	if string.find(name, "_") then
		name = family(name)
	end

	-- That feeling when no enums/switch case
	local favor = beeData.biomeLikeness[name][biome] or 2 --default is "liked" with no bonus to production

	--frame immunity to biomes
	if frameBonuses.radResistance then
		if (biome == "alien") or (biome == "jungle") or (biome == "barren") or (biome == "barren2") or (biome == "barren3") or (biome == "chromatic") or (biome == "irradiated") or (biome == "metallicmoon") then
		  if (favor < 2) then
		    favor = 2
		  end
		end
	elseif frameBonuses.coldResistance then
		if (biome == "snow") or (biome == "arctic") or (biome == "snowdark") or (biome == "arcticdark") or (biome == "tundra") or (biome == "tundradark") or (biome == "crystalmoon") or (biome == "frozenvolcanic") or (biome == "icemoon") or (biome == "icewaste") or (biome == "icewastedark") or (biome == "nitrogensea") then
		  if (favor < 2) then
		    favor = 2
		  end
		end
	elseif frameBonuses.heatResistance then
		if (biome == "desert") or (biome == "volcanic") or (biome == "volcanicdark") or (biome == "magma") or (biome == "magmadark") or (biome == "desertwastes") or (biome == "desertwastesdark") or (biome == "infernus") or (biome == "infernusdark") or (biome == "frozenvolcanic") then
		  if (favor < 2) then
		    favor = 2
		  end
		end
	elseif frameBonuses.physicalResistance then
		if (biome == "toxic") or (biome == "moon") or (biome == "scorched") or (biome == "scorchedcity") or (biome == "volcanic") or (biome == "volcanicdark") or (biome == "savannah")  or (biome == "jungle") or (biome == "thickjungle") or (biome == "sulphuric") or (biome == "sulphuricdark") or (biome == "tidewater") then
		  if (favor < 2) then
		    favor = 2
		  end
		end
	end

	if favor == 0 then return -1 end -- deadly - halts production
	if favor == 1 then return beeData.biomeDisliked end
	if favor == 2 then return beeData.biomeLiked end
	if favor == 3 then return beeData.biomeFavorite end
end

-- Used to handled animation. Base = the apiary itself, bees = the bees flying around, loading = loading sign
function setAnimationStates(base, bees, loading, warning)
	if oldBaseState ~= base then
		oldBaseState = base

		if base then
			animator.setAnimationState("base", "default", true)
		else
			animator.setAnimationState("base", "disabled", true)
		end
	end

	if oldBeeState ~= bees then
		oldBeeState = bees

		if bees then
			animator.setAnimationState("bees", "on", true)
		else
			animator.setAnimationState("bees", "off", true)
		end
	end

	if oldLoadingState ~= loading then
		oldLoadingState = loading

		if loading then
			animator.setAnimationState("loading", "on", true)
		else
			animator.setAnimationState("loading", "off", true)
		end
	end
end

-- Check whether there aren't too many bees entities flying about
function spaceForBees()
	local bees = world.monsterQuery(entity.position(), beeData.beeEntityCheckRadius, { callScript = 'getClass', callScriptResult = 'bee' })
	local apiaries = world.entityQuery(entity.position(), beeData.beeEntityCheckRadius, { withoutEntityId = entity.id(), callScript = 'getClass', callScriptResult = 'apiary' })
	return #bees < beeData.maxBeeEntities + beeData.extraBeeEntitiesPerApiary * #apiaries
end

-- Attempt spawning a bee entity to roam about
function tryBeeSpawn(family, genome)
	if math.random() <= beeData.beeSpawnChance and spaceForBees() then
		if math.random(20)>= 15 then
			world.spawnMonster(string.format("bee_%s", family), object.toAbsolutePosition({ 2, 3 }), { genome = genome })
		end
	end
end

-- Get flower likeness based on the bees subtype
function getFlowerLikeness(beeSubtype)
	local objects = world.objectQuery(entity.position(), beeData.flowerSearchRadius, {withoutEntityId = entity.id(), order = "nearest"})
	if (#objects < 1) then return -1 end

	local flowerCount = 0
	local flowerModifier = 0
	for _, id in ipairs(objects) do

		-- Gets the farmables stage, or nil if its not a farmable
		local stage = world.farmableStage(id)
		if stage then
			local stages = world.getObjectParameter(id, "stages", nil)
			local likenessTable = world.getObjectParameter(id, "beeLikeness", nil)
			local addition

			if likenessTable and likenessTable[beeSubtype] then
				addition = likenessTable[beeSubtype]
			else
				addition = beeData.flowerDefaultLikeness
			end

			if stage > #stages - 2 then
				addition = addition * beeData.flowerLastTwoStagesModifier
			else
				addition = addition * beeData.flowerLowerStagesModifier
			end

			flowerCount = flowerCount + 1
			if flowerCount > beeData.flowerMinimum then
				flowerModifier = flowerModifier + addition * beeData.flowerExtrasFavorModifier
			else
				flowerModifier = flowerModifier + addition
			end

			if flowerCount == beeData.flowerMaximum then break end
		end
	end

	-- Separate formulas for minimum flowers, and more than minimum
	if (flowerCount <= beeData.flowerMinimum) then
		flowerModifier = flowerModifier / (beeData.flowerMinimum / flowerCount)
	end

	--if (flowerModifier < beeData.flowerMinimumModifierToWork) then
		--return -1 end
	return flowerModifier
end
