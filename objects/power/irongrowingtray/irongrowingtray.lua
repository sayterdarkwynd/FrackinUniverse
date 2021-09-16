require "/scripts/fu_storageutils.lua"
require "/scripts/kheAA/transferUtil.lua"
require "/scripts/fupower.lua"

timer = 0

seedslot = 0
waterslot = 1
fertslot = 2

inputSlots = {seedslot, waterslot, fertslot}

function init()

	if storage.state == nil then storage.state = config.getParameter("defaultLightState", false) end
	setLightState(storage.state)


	defaults = {
		growthRate = config.getParameter("baseGrowthPerSecond", 3),  -- Multiplier on vanilla plant growth speed
		seedUse = config.getParameter("defaultSeedUse", 3),          -- Amount of seeds consumed per plant (for perennials, starting cost)
		yield = config.getParameter("baseYields", 3),                -- Multiplier on treasurepools generated
		fluidUse = config.getParameter("defaultWaterUse", 1)         -- Fluid units consumed per stage
		-- geneBonus   the bonus granted by X when attempting to mutate the strain
		-- seedUseMutation    chance for spontaneous mutation/gene treatment
		-- yieldMutation     chance for spontaneous mutation/gene treatment
		-- ??
		-- ??
	}
	multipliers = { growthRate=true } -- Which stats should be calculated as multipliers

	if not storage.fert then storage.fert = {} end
	if not storage.water then storage.water = {} end

	self.requiredPower = config.getParameter("isn_requiredPower")
	self.unpoweredGrowthRate = config.getParameter("unpoweredGrowthRate", 0.434782609)   -- Multiplier on base growth rate when unpowered
	self.liquidInputs = config.getParameter("waterInputs")
	self.fertInputs = config.getParameter("fertInputs")

	if self.requiredPower then
		power.init()
	end

	object.setInteractive(true)

	storage.growth = storage.growth or 0 				--Plant growth completed
	storage.fluid = storage.fluid or 0					--Stored fluid
	storage.currentStage = storage.currentStage or 1	--Current plant stage
	storage.hasFluid = storage.hasFluid or false		--If false soil is dry and no further growth.

	if storage.activeConsumption == nil then storage.activeConsumption = false end
end

--Updates the state of the object.
function update(dt)
	-- Updates container status (for ITD management)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end


	-- Check tray inputs
	local water,fert=checkTrayInputs()
	storage.activeConsumption = false

	if self.requiredPower then power.update(dt) end

	--Try to start growing if data indicates we aren't.
	if not storage.currentseed then
		if not doSeedIntake() then
			-- Player feedback, when not growing, turn off the lights.
			if self.requiredPower then
				animator.setAnimationState("powlight", "off")
				storage.state = false
				setLightState(storage.state)
			end
				if object.outputNodeCount() > 0 then
					object.setOutputNodeLevel(0,false)
				end
			handleTooltip({water=water,fert=fert,growthmod=nil})--update description
			return
		end
	end

	--growthmod should be nil if we aren't a power consumer
	local growthmod = self.requiredPower and ((consumePower(dt) and 1) or self.unpoweredGrowthRate)
	--sb.logInfo("growthmod: %s",growthmod)
	growPlant(growthmod, dt)

	handleTooltip({water=water,fert=fert,growthmod=growthmod,seed=storage.currentseed})--update description

	storage.activeConsumption = true
	if object.outputNodeCount() > 0 then
		object.setOutputNodeLevel(0,true)
	end


	updateState()
end

--Tries to relocate an item in a specific slot while avoiding key slots.
--If all the item stack in a slot can't be moved remainder is put back and overflow is returned.
local function fu_relocateItem(slot, avoidSlots)
	local item = world.containerTakeAt(entity.id(), slot)
	-- Use store instead of send/store to avoid confusion of item possibly being consumed.
	local overflow = fu_storeItems(item, avoidSlots)
	if overflow then
		world.containerPutItemsAt(entity.id(), overflow, slot)
		return overflow
	end
	return
end

-- Checks tray water and fertilizer inputs for validity.
-- Pushes invalid items into storage (if there is room).
-- Updates description based on inputs.
-- Only does work if state of inputs has changed.
-- NOTE: Intentionally does not check seed input slot.
function checkTrayInputs()
	-- Gather information about the items in input slots
	local inputWater = world.containerItemAt(entity.id(), waterslot)
	local inputFert = world.containerItemAt(entity.id(), fertslot)

	-- Cache check, if key details are unchanged then there is no work to do.
	local bWater = not inputWater and not storage.cacheWater or
			inputWater and storage.cacheWater and inputWater.name == storage.cacheWaterName
	local bFert = not inputFert and not storage.cacheFert or
			inputFert and storage.cacheFert and inputFert.name == storage.cacheFertName
	if bWater and bFert then return end

	-- Fetch tray data for inputs.
	local water = inputWater and self.liquidInputs[inputWater.name] or nil
	local fert = inputFert and self.fertInputs[inputFert.name] or nil



	-- Relocate invalid inputs
	if inputWater and not water then inputWater = fu_relocateItem(waterslot, inputSlots) end
	if inputFert and not fert then inputFert = fu_relocateItem(fertslot, inputSlots) end

	-- Update cache
	storage.cacheWaterName = inputWater and inputWater.name or nil
	storage.cacheFertName = inputFert and inputFert.name or nil


	return water,fert
end


-- Generate new description
function handleTooltip(args)

	--growth rate and power calc
	local growthrate=getFertSum('growthRate', args.fert, args.water)
	local growthrate2=growthrate*(args.growthmod or 1)
	growthrate=util.round(growthrate,2)
	growthrate2=util.round(growthrate2,2)
	local growthString
	local powerString=""
	if growthrate~=growthrate2 and self.requiredPower then
		growthString='Growth Rate: ^red;' .. growthrate2 .. "^reset;\n"
		powerString=powerString.."Power: ^red;0^reset;/"..self.requiredPower.."\n"
	elseif self.requiredPower then
		growthString='Growth Rate: ^green;' .. growthrate .. "^reset;\n"
		if not args.growthmod then
			powerString=powerString.."Power: 0/"..self.requiredPower.."\n"
		else
			powerString=powerString.."Power: ^green;"..self.requiredPower.."^reset;/"..self.requiredPower.."\n"
		end
	else
		growthString='Growth Rate: ^green;' .. growthrate2 .. "^reset;\n"
	end

	--seed use and seed display
	local seedString=""
	if args.seed and args.seed.name then
		seedString=root.itemConfig(args.seed.name).config.shortdescription
		seedString=" (^yellow;" .. seedString .. "^reset;)"
	end

	local seedUseWith=getFertSum('seedUse', args.fert, args.water)
	local seedUseWithout=getFertSum('seedUse', "absolutelynothing", "absolutelynothing")
	if seedUseWith<seedUseWithout then
		seedUseWith="^green;"..seedUseWith.."^reset;"
	elseif seedUseWith>seedUseWithout then
		seedUseWith="^red;"..seedUseWith.."^reset;"
	end
	seedString='Seeds Used: ' .. seedUseWith .. seedString .. "\n"

	--yield calc
	local yieldWith=getFertSum('yield', args.fert, args.water)
	local yieldWithout=getFertSum('yield', "absolutelynothing", "absolutelynothing")
	if yieldWith>yieldWithout then
		yieldWith="^green;"..yieldWith.."^reset;"
	elseif yieldWith<yieldWithout then
		yieldWith="^red;"..yieldWith.."^reset;"
	end
	local yieldString='Yield Count: ' .. yieldWith .. "\n"

	--water use calc
	local waterUseWith=getFertSum('fluidUse', args.fert, args.water)
	local waterUseWithout=getFertSum('fluidUse', "absolutelynothing", "absolutelynothing")
	if waterUseWith<waterUseWithout then
		waterUseWith="^green;"..waterUseWith.."^reset;"
	elseif waterUseWith>waterUseWithout then
		waterUseWith="^red;"..waterUseWith.."^reset;"
	end
	local waterUseString='Water Use: ' .. waterUseWith .. "\n"


	--water value calc
	local waterValueString='Water Value: '
	local waterValue=(args.water and args.water.value or 0)
	if waterValue>0 then
		waterValueString=waterValueString.."^green;"..waterValue.."^reset;"
	else
		waterValueString=waterValueString..waterValue
	end

	--set desc!
	local desc = powerString..seedString..yieldString..growthString..waterUseString..waterValueString
	object.setConfigParameter('description', desc)
end

--Returns active seed when tray is removed from world
function die()
	if storage.currentseed then
		storage.currentseed.count = getFertSum("seedUse")
		world.spawnItem(storage.currentseed, entity.position())
	end
end

-- Consumes power and updates animation
function consumePower(dt)
	if self.requiredPower then
		if power.consume(self.requiredPower * dt) then
			animator.setAnimationState("powlight", "on")
			storage.state = true
			setLightState(storage.state)
			return true
		else
			animator.setAnimationState("powlight", "off")
			setLightState(storage.state)
			storage.state = false

			return false
		end
	end
	return false
end

-- Upates growth animation
function updateState()
	--Compute which graphic should be displayed and update.
	local growthperc = (storage.growthcap ~= 0) and (100*math.min(storage.growth, storage.growthCap)/storage.growthCap) or 0
	animator.setAnimationState("growth", sb.print(math.min(math.floor(growthperc / 25), 3)))
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

		local seedavoid = {waterslot, fertslot}   		-- Map for allowing seeds to be output into the input slot
		for _,item in ipairs(output) do
			-- Preserve customized seeds on output
			if item.name == storage.currentseed.name then
				item.parameters = storage.currentseed.parameters
			end
			fu_sendOrStoreItems(0, item, item.name == storage.currentseed.name and seedavoid or inputSlots)
		end

		-- Perennial plants should return yeild of seeds for balance purposes.
		-- By returning yield seeds we handle part of perennials regrowing from the same seed.
		if stage().resetToStage then
			storage.currentseed.count = getFertSum("yield")
			fu_sendOrStoreItems(0, storage.currentseed, seedAvoid)
			storage.perennialSeedName = storage.currentseed.name
		end

		-- Done growing reset for next cycle.
		storage.currentseed = nil
	end
end

-- Gets the current effective value of a fertilizer-affected modifier.
function getFertSum(name, fert, water)
	fert = fert or storage.fert
	water = water or storage.water
	if multipliers[name] then
		local rate = (fert[name] or 1) * (water[name] or 1)
		return defaults[name] * (rate <= 0 and 1 or rate)
	end
	local bonus = (fert[name] or 0) + (water[name] or 0)
	return math.max(defaults[name] + bonus, 0)
end

--Updates internal fluid levels, consumes required fluid units, and updates any fluid bonuses.
--optional arg fluidNeed is amount of fluid required to top up to.
function doWaterIntake(fluidNeed)
	local water = world.containerItemAt(entity.id(), waterslot)

	if water and self.liquidInputs[water.name] then
		storage.water = self.liquidInputs[water.name]
		local amt = math.min(water.count, math.ceil(fluidNeed / storage.water.value))
		storage.fluid = storage.fluid + (amt * storage.water.value)
		world.containerConsumeAt(entity.id(),waterslot,amt)
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
	local seed = world.containerItemAt(entity.id(), seedslot)
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
	if storage.currentseed.name == "sapling" then return false end
	local stages = (storage.currentseed.parameters and storage.currentseed.parameters.stages) or root.itemConfig(storage.currentseed).config.stages
	storage.stages = #stages
	storage.stage = stages
	return true
end

--[[
Notes on how Starbound handles perennials and reason for some odd code below.
First, Starbound, in C, is 0 based arrays while Lua is 1 based arrays. (resetToStage + 1)
Second, Starbound appears to do bounds checking on the resetToStage property. (min & max calls)
Third, Starbound gracefully handles if a seed changes data, mods (resetToStage check in if condition)
]]--
--Generates growth data to tell when a plant is ready for harvest and when it
--needs to be watered.
--Also handles some of perennial growth mechanics.
function genGrowthData()
	storage.growthCap = 0
	for index,stage in ipairs(storage.stage) do
		storage.growthCap = storage.growthCap + (stage.duration and stage.duration[1] or 0)
		stage.val = storage.growthCap
	end

	-- Set currentStage and possibly growth depending on perennial seed data
	if storage.perennialSeedName and storage.stage[storage.stages].resetToStage and
			storage.currentseed.name == storage.perennialSeedName then
		storage.currentStage = math.min(storage.stages, math.max(1, storage.stage[storage.stages].resetToStage + 1))
		storage.growth = storage.currentStage == 1 and 0 or	storage.stage[storage.currentStage - 1].val
	else
		storage.currentStage = 1
	end
	--Clear the old perennial data.
	storage.perennialSeedName = nil
end

--Initialize plant activity
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
		storage.fert = {}
		return false
	end

	--Generate growth data.
	genGrowthData()

	--All state tests passed and we are ready to grow, consume some items.

	--Consume a unit of fertilizer.
	if fertName then
		world.containerConsumeAt(entity.id(),fertslot,1)
	end

	--Consume seed.
	world.containerConsumeAt(entity.id(),seedslot,getFertSum("seedUse"))

	return true
end

--Reads the current fertilizer slot and modifies growing state data
--Returns false if nothing to do, true if successful
function doFertProcess()
	local fert = world.containerItemAt(entity.id(), fertslot)

	if fert and self.fertInputs[fert.name] and fert.count > 0 then
		storage.fert = self.fertInputs[fert.name]
		return fert.name
	end
	storage.fert = {}
	return nil
end

function resetBonuses()
	storage.fert = {}
	storage.water = {}
end

function setLightState(newState)
  if newState then
    object.setSoundEffectEnabled(true)
    if animator.hasSound("on") then
      animator.playSound("on");
    end
    --TODO: support lightColors configuration
    object.setLightColor(config.getParameter("lightColor", {255, 255, 255}))
  else
    object.setSoundEffectEnabled(false)
    if animator.hasSound("off") then
      animator.playSound("off");
    end
    object.setLightColor(config.getParameter("lightColorOff", {0, 0, 0}))
  end
end


