require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/power.lua"

seedslot = 1
waterslot = 2
fertslot = 3

function init()
	defaults = {
		growthRate = config.getParameter("baseGrowthPerSecond", 4),  -- Multiplier on vanilla plant growth speed
		seedUse = config.getParameter("defaultSeedUse", 3),          -- Amount of seeds consumed per plant (for perennials, starting cost)
		yield = config.getParameter("baseYields", 1),                -- Multiplier on treasurepools generated
		fluidUse = config.getParameter("defaultWaterUse", 1)         -- Fluid units consumed per stage
		-- geneBonus   the bonus granted by X when attempting to mutate the strain
		-- seedUseMutation    chance for spontaneous mutation/gene treatment
		-- yieldMutation     chance for spontaneous mutation/gene treatment
		-- ??
		-- ??
	}

	if not storage.fert then storage.fert = {} end
	if not storage.water then storage.water = {} end

	self.requiredPower = config.getParameter("isn_requiredPower", nil)
	self.unpoweredGrowthRate = config.getParameter("unpoweredGrowthRate", 0.434782609)   -- Multiplier on base growth rate when unpowered
	self.liquidInputs = config.getParameter("waterInputs")
	self.fertInputs = config.getParameter("fertInputs")

	if self.requiredPower then
		power.init()
	end

	transferUtil.init()
	object.setInteractive(true)

	storage.growth = storage.growth or 0 				--Plant growth completed
	storage.fluid = storage.fluid or 0					--Stored fluid
	storage.currentStage = storage.currentStage or 1	--Current plant stage
	storage.hasFluid = storage.hasFluid or false		--If false soil is dry and no further growth.

	if storage.activeConsumption == nil then storage.activeConsumption = false end
end

--Updates the state of the object.
function update(dt)
	if self.requiredPower then power.update(dt) end

	storage.activeConsumption = false

	--Try to start growing if data indicates we aren't.
	if not storage.currentseed then
		if not doSeedIntake() then return end
	end

	local growthmod = consumePower(dt) and 1 or self.unpoweredGrowthRate
	growPlant(growthmod, dt)

	storage.activeConsumption = true

	updateState()
end

--Returns active seed when tray is removed from world
function die()
	if storage.currentseed then
		local count = getFertSum("seedUse")
		storage.currentseed.count = 1
		world.spawnItem(storage.currentseed, entity.position(), count)
	end
end

-- Consumes power and updates animation
function consumePower(dt)
	if self.requiredPower then
		if power.consume(self.requiredPower * dt) then
			animator.setAnimationState("powlight", "on")
			return true
		else
			animator.setAnimationState("powlight", "off")
			return false
		end
	end
	return false
end

-- Upates growth animation
function updateState()
	--Compute which graphic should be displayed and update.
	local growthperc = isn_getXPercentageOfY(math.min(storage.growth, storage.growthCap), storage.growthCap)
	animator.setAnimationState("growth", sb.print(math.floor(growthperc / 25)))
end

-- Performs a plant growth tick, including water consumption and harvesting
function growPlant(growthmod, dt)
	-- Little cheat ;-) (always gets current stage)
	local stage = function() return storage.stage[storage.currentStage] end

	-- Fluid check
	storage.hasFluid = doFluidConsume()
	if not storage.hasFluid then return end

	-- Add growth
	storage.growth = storage.growth + getFertSum("growthRate") * (growthmod or 1) * dt

	-- If current stage is complete, consume fluid units and increment stage
	if storage.growth >= stage().val then
		storage.fluid = storage.fluid - getFertSum("fluidUse")
		storage.currentStage = storage.currentStage + 1
	end

	-- If the new stage is a harvesting stage, harvest and handle perennial
	if stage().harvestPool then
		local tblmerge = function(tb1, tb2) for k,v in pairs(tb2) do table.insert(tb1, v) end end
		local output = {}
		for i=1,getFertSum("yield") do
			tblmerge(output, root.createTreasure(stage().harvestPool, 1))
		end

		local avoid = {0, 1, 2}    -- Map for avoiding output to input slots
		local seedavoid = {1, 2}   -- Map for allowing seeds to be output into the input slot
		for _,item in ipairs(output) do
			-- Preserve customized seeds on output
			if item.name == storage.currentseed.name then
				item.parameters = storage.currentseed.parameters
			end
			fu_sendOrStoreItems(0, item, item.name == storage.currentseed.name and seedavoid or avoid)
		end

		-- Go to reset stage for perennial plants and full reset for others
		local seed = world.containerItems(entity.id())[seedslot]
		if seed and seed.name ~= storage.currentseed.name then
			storage.currentseed.count = 1
			fu_sendOrStoreItems(0, storage.currentseed, avoid)
			storage.currentStage = 1
			storage.growth = 0
			storage.currentseed = nil
		elseif stage().resetToStage then
			storage.currentStage = stage().resetToStage
			storage.growth = stage().val
			resetBonuses()
			doFertProcess()
			storage.hasFluid = doFluidConsume()
		else
			storage.currentStage = 1
			storage.growth = 0
			storage.currentseed = nil
		end
	end
end

-- Gets the current effective value of a fertilizer-affected modifier.
function getFertSum(name)
	return defaults[name] + (storage.fert[name] or 0) + (storage.water[name] or 0)
end

--Updates internal fluid levels, consumes required fluid units, and updates any fluid bonuses.
--optional arg fluidNeed is amount of fluid required to top up to.
function doWaterIntake(fluidNeed)
	local water = world.containerItems(entity.id())[waterslot]

	if water and self.liquidInputs[water.name] then
		storage.water = self.liquidInputs[water.name]
		local amt = math.min(water.count, math.ceil(fluidNeed / storage.water.value))
		storage.fluid = storage.fluid + (amt * storage.water.value)
		sb.logInfo("Consuming "..amt.." water; ".."Needed "..fluidNeed.." units")
		world.containerConsume(entity.id(), {name = water.name, count = amt})
		return true
	end
	storage.water = {}
	return false
end

--Attempts to use up some fluid
function doFluidConsume()
	local useFluid = getFertSum("fluidUse")
	if storage.fluid < useFluid then
		if not doWaterIntake(useFluid - storage.fluid) then return false end
	end
	return true
end

--Fetch the seed from the storage slot, also does validity check.
function readContainerSeed()
	local seed = world.containerItems(entity.id())[seedslot]
	if not seed then return end
	--Verify the seed is valid for use.
	local seedConfig = root.itemConfig(seed).config
	if seedConfig.objectType ~= "farmable" then return nil end
	return seed
end

--Reads the currentseed's data.  Return false if there was a problem with the
--seed/data.
function readSeedData()
	if not storage.currentseed then return false end
	local stages = (storage.currentseed.parameters and storage.currentseed.parameters.stages) or root.itemConfig(storage.currentseed).config.stages
	storage.stages = #stages
	storage.stage = stages
	return true
end

--Generates growth data to tell when a plant is ready for harvest and when it
--needs to be watered.
function genGrowthData(initStage)
	initStage = initStage or 1
	--Make sure some things make sense for a perennial, if not act like it's annual
	if initStage > storage.stages then
		initStage = 1
		storage.resetStage = 1
	end
	storage.currentStage = initStage
	storage.growthCap = 0
	for index,stage in ipairs(storage.stage) do
		storage.growthCap = storage.growthCap + (stage.duration and stage.duration[1] or 0)
		stage.val = storage.growthCap
	end
	return true
end

--Initialize plant activity (start from scratch)
function doSeedIntake()
	storage.growth = 0
	animator.setAnimationState("growth", "0")
	storage.currentseed = nil

	--Read/init seed data
	local seed = readContainerSeed()
	if not seed then return false end
	storage.currentseed = seed
	if not readSeedData() then
		storage.currentseed = nil
		return false
	end

	--set defaults that fertilizer can change or modify
	resetBonuses()

	--Since we might need to consume multiple seeds we delay fertilizer USE
	--until we know we have enough resources to proceed.
	--Otherwise we could end up consuming all the fertilizer without growing anything.
	local fertName = doFertProcess()

	--verify we have enough seeds to proceed.
	if storage.currentseed.count < getFertSum("seedUse") then
		storage.currentseed = nil
		storage.harvestPool = nil
		return false
	end

	--Generate growth data.
	if not genGrowthData() then
		storage.currentseed = nil
		storage.harvestPool = nil
		return false
	end
	--All state tests passed and we are ready to grow, consume some items.

	--Consume a unit of fertilizer.
	if fertName then
		storage.fert = self.fertInputs[fertName]
		world.containerConsume(entity.id(), {name = fertName, count = 1, data={}})
	end

	--Consume seed.
	world.containerConsume(entity.id(), {name = seed.name, count = getFertSum("seedUse"), data={}})

	return true
end

--Reads the current fertilizer slot and modifies growing state data
--Returns false if nothing to do, true if successful
function doFertProcess()
	local fert = world.containerItems(entity.id())[fertslot]

	if fert and self.fertInputs[fert.name] and fert.count > 0 then
		return fert.name
	end
	storage.fert = {}
	return nil
end

function resetBonuses()
	storage.fert = {}
	storage.water = {}
end
