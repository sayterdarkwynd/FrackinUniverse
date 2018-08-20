require "/scripts/kheAA/transferUtil.lua"

local contents
DEFAULT_HONEY_CHANCE = 0.6
DEFAULT_OFFSPRING_CHANCE = 0.4

--  CONCEPTUAL STUFF
--local lastTimeEdited = os.clock()
--if os.clock() >= lastTimeEdited + timeDiff then
-- do your update conditions.
--end
--use the above to track time for bee maturation while player isnt present
--





--[

function init()
  --base values are set here
	transferUtil.init()


	animator.setAnimationState("bees", "off")

	if not self.spawnDelay or not contents then
		self.queenSlot = config.getParameter ("queenSlot")				-- Apiary inventory slot number (indexed from 1)
		self.droneSlot = config.getParameter ("droneSlot")				--
		self.frameSlots = config.getParameter ("frameSlots")

		self.spawnDelay = config.getParameter("spawnDelay")				-- A global spawn rate multiplier. Higher is slower.
		self.spawnBeeBrake = config.getParameter("spawnBeeBrake")   	-- Individual spawn rates. Set to nil if none to be spawned.
		self.spawnItemBrake = config.getParameter("spawnItemBrake")		--
		self.spawnHoneyBrake = config.getParameter("spawnHoneyBrake")	--
		self.spawnDroneBrake = config.getParameter("spawnDroneBrake")	--
		self.limitDroneCount = config.getParameter("limitDroneCount")	-- whether to limit the number of drones

		self.beeStingChance = config.getParameter("beeStingChance")		-- chance of being stung by the aggressive varieties
		self.beeStingOffset = config.getParameter("beeStingOffset")		-- spawn offset of the sting object (0,0 if not set)

		self.beePowerScaling = config.getParameter("beePowerScaling")	-- scaling factor for cooldown modification in deciding()

		self.honeyModifier = 0		-- modifiers for frames, higher means faster production
		self.itemModifier = 0		--
		self.droneModifier = 0		--
		self.mutationIncrease = 0   --
                self.honeyAmount = 0 --

                -- new FU properties for apiaries
                self.miteReduction = config.getParameter("miteReduction",0)
                self.mitePenalty = config.getParameter("mitePenalty",0)
                self.mutationMultiplier = config.getParameter("mutationMultiplier",0)

		self.config = root.assetJson('/objects/bees/apiaries_new.config')	-- common apiaries configuration
		self.functions = { chooseMinerHoney = chooseMinerHoney, chooseMinerOffspring = chooseMinerOffspring }

		initAntimiteFrames()
		reset()
		return true
	end
	return false
end

function initAntimiteFrames()
end



function findBeeType() --gonna need an if/else for if it isnt a queen/drone pair
	local queen, drone = getEquippedBees() --get names of queen and drone
	if queen and drone then
		if queen == drone and self.config.beeProperties[queen] then
			local properties = self.config.beeProperties[queen] -- taken from how spawnList works in workingBees()
			self.beeType = properties.beeType
		elseif queen ~= drone
			then self.beeType = 'mismatch'
		end
	else
		beeType = 'nobees'
	end
	return self.beeType --returns bee family
end


function findHiveAge()

end

function findFrameType()  -- call frames *after* bee age/hive age and type is determined
end

function applyFrameType()  -- apply frame bonuses/penalties and stat changes
end

function mateBees()  --call mate before mutate
end

function findMutationChance()
end

function applyMutation()
end



function reset()   ---When bees are not present, this sets a slightly increased timer for when bees are added again.

end

--]




function initAntimiteFrames()
	self.antimiteFrames = {}
	for frame, mods in pairs(self.config.modifiers) do
		if mods.antimite then
			self.antimiteFrames[frame] = true
		end
		--if mods.miteReduction then
		--	self.miteReduction = mods.miteReduction
		--end
		--if mods.mitePenalty then
		--	self.mitePenalty = mods.mitePenalty
		--end
	end
end


function reset()   ---When bees are not present, this sets a slightly increased timer for when bees are added again.
	if self.spawnBeeBrake   then self.spawnBeeCooldown   = self.spawnBeeBrake   * 2 end
	if self.spawnItemBrake  then self.spawnItemCooldown  = self.spawnItemBrake  * 2 end
	if self.spawnHoneyBrake then self.spawnHoneyCooldown = self.spawnHoneyBrake * 2 end
	if self.spawnDroneBrake then self.spawnDroneCooldown = self.spawnDroneBrake * 2 end
	self.beePower = 0
	self.flowerPower = 0
	self.vegetablePower = 0
	self.fruitPower = 0
	contents = world.containerItems(entity.id())
end


function frame()
	contents = world.containerItems(entity.id())
	local mods = { combs = {} }

	for key, slot in ipairs(self.frameSlots) do
		apiary_doFrame(mods, contents[slot])
	end

	self.droneModifier = mods.droneModifier or 0
	self.honeyModifier = mods.honeyModifier or 0
	self.itemModifier = mods.itemModifier or 0
	self.mutationIncrease = mods.mutationIncrease or 0
	self.antimite = mods.antimite

	if mods.forceTime and mods.forceTime ~= 0 then
		daytime = mods.forceTime > 0
	end

	self.combs = mods.combs
--[[
	sb.logInfo ('apiary ' .. entity.id() .. ': drone ' .. self.droneModifier .. ', honey ' .. self.honeyModifier .. ', item ' .. self.itemModifier .. ', muta ' .. self.mutationIncrease)
	for key, slot in ipairs(self.frameSlots) fo
		if contents[slot] then sb.logInfo ('apiary ' .. entity.id() .. ' contains ' .. contents[slot].name) end
	end
--]]
end


function apiary_doFrame(mods, item)
--- Check the type of frame. Adjust variables-------------
--- A 600 cooldown, with 30 beepower, is now reduced to a 570 cooldown. 30 beepower = 60 reduced per second, or 9.5 seconds, instead of 10.
	if item and item.name then
		local patch

		-- Production rate modifiers etc.
		patch = self.config.modifiers[item.name]
		if patch then
			for key, value in pairs(patch) do
				if not value or value == true then
					mods[key] = value
				else
					mods[key] = (mods[key] or 0) + value
				end
			end
		end

		-- Miner bees' ore combs
		patch = self.config.ores[item.name]
		if patch then
			mods.combs[patch] = (mods.combs[patch] or 0) + 1
		end
	end
end


function stripQueenDrone(s)
	return s:gsub("drone$", ""):gsub("queen$", "")
end

function getEquippedBees()
	contents = world.containerItems(entity.id())

	local queen = contents[self.queenSlot]
	local drone = contents[self.droneSlot]

	self.beePower = -1 -- default
	if not queen and not drone then return end -- nothing there

	local queenName = queen and stripQueenDrone(queen.name)
	local droneName = drone and stripQueenDrone(drone.name)

	if queenName and droneName then
		-- Apiaries function faster with more drones. 64 drones work just over twice as effecient as 1 drone. (well, exactly (13/6) times)
		local count

		if queen.name == queenName .. 'queen' and drone.name == droneName .. 'drone' then
			count = drone.count
		elseif queen.name == queenName .. 'drone' and drone.name == droneName .. 'queen' then
			queenName, droneName = droneName, queenName -- ensure that we return queen, drone when content is drone, queen
			count = queen.count
		end

		if count then
		--Beepower = cooldown reduction rate. At 500ms scriptDelta, and with 20 beePower, it takes 5 seconds to reduce a 200 cooldown to 0.
			self.beePower = math.ceil(math.sqrt(count) + 10)
			return queenName, droneName
		end
	end
end


function spaceForBees()
	local bees = world.monsterQuery(entity.position(), 25, { callScript = 'getClass', callScriptResult = 'bee' })
	local apiaries = world.entityQuery(entity.position(), 25, { withoutEntityId = entity.id(), callScript = 'getClass', callScriptResult = 'apiary' })
	return #bees < 15 + 2 * #apiaries
end


function getClass()
	return 'apiary'
end


function trySpawnBee(chance,type)
	-- tries to spawn bees if we haven't in this round
	-- Type is normally things "normal" or "bone", as the code inputs them in workingBees() or breedingBees(), this function uses them to spawn bee monsters. "normalbee" for example.
	-- chance is a float value between 0.00 (will never spawn) and 1.00 (will always spawn)
	if self.doBees and math.random(100) <= 100 * chance and spaceForBees() then
		world.spawnMonster(type .. "bee", object.toAbsolutePosition({ 2, 3 }), { level = 1 })
		self.doBees = false
	end
end


function trySpawnMutantBee(chance,type)
	if self.doBees and math.random(100) <= 100 * (chance + self.mutationIncrease) and spaceForBees() then
		world.spawnMonster(type .. "bee", object.toAbsolutePosition({ 2, 3 }), { level = 1 })
		self.doBees = false
	end
end


function droneStarter()
	-- Spawn more drones in newer apiaries.
	-- Drone QTY:  1-40       41-80
	-- Spawn QTY:  +2         +1     (This adds to the function trySpawnDrone: amount)
	local bonus, reduce = 0, false

	if contents[self.queenSlot] and contents[self.droneSlot] then
		local beeQuanity = ((contents[self.queenSlot].count + contents[self.droneSlot].count) - 1)      -- I subtracted 1 since the queen inflates the total. Keep in mind either slot could be drones, easiest to add them and then subtract.
		if beeQuanity < 81 then
			bonus = math.ceil((81 - beeQuanity) / 40)
		elseif self.limitDroneCount == true and beeQuanity > 200 then
			reduce = true
		end
	end

	return bonus, reduce
end


function trySpawnDrone(chance,type,amount)
	if self.doDrones and math.random(100) <= 100 * chance then
		local bonus, reduce = droneStarter()
		if reduce then
			world.containerConsume(entity.id(), {name =type .. "drone", count = math.random(5), data={}})
		end
		amount = amount or (math.random(2) + bonus)
		world.containerAddItems(entity.id(), { name=type .. "drone", count = amount, data={}})
		self.doDrones = false
	end
end


function trySpawnMutantDrone(chance,type,amount)
	if self.doDrones and math.random(100) <= 100 * (chance + self.mutationIncrease) then
		world.containerAddItems(entity.id(), { name=type .. "drone", count = amount or 1, data={}})
		self.doDrones = false -- why was this doItems?
	end
end


function trySpawnItems(chance,type,amount)
	-- analog to trySpawnBee() for items (like goldensand)
	if self.doItems and math.random(100) <= 100 * chance then
		world.containerAddItems(entity.id(), { name=type, count = amount or 1, data={}})
		self.doItems = false
	end
end


function trySpawnHoney(chance,honeyType,amount)
	if not self.doHoney then return nil end  --if the apiary isn't spawning honey, do nothing
	amount = amount or 1  --- if not specified, just spawn 1 honeycomb.
	local flowerIds = world.objectQuery(entity.position(), 25, {name="beeflower", order="nearest"})  --find all flowers within range

	if (math.random(100) / (#flowerIds * 3 + 100) ) <= chance then   --- The more flowers in range, the more likely honey is to spawn. Honey still spawns 1 at a time, at the same interval
		world.containerAddItems(entity.id(), { name=honeyType .. "comb", count = amount + self.honeyAmount , data={}})
		self.doHoney = false
	end
end


function expelQueens(type)   ---Checks how many queens are in the apiary, either under the first or second bee slot, and removes all but 1. The rest will be dropped on the ground. Only functions when the apiary is working.
	contents = world.containerItems(entity.id())
	local queenLocate = type .. "queen"  ---Input the used bee type, and create a string such as "normal" .. "queen" = "normalqueen"

	local slot = nil
	if contents[self.queenSlot].name == queenLocate then
		slot = self.queenSlot
	elseif contents[self.droneSlot].name == queenLocate then
		slot = self.droneSlot
	end

	if slot and contents[slot].count > 1 then								---how many queens, exactly?
		local queenname = contents[slot].name								---sets the variable queenname to be use for queen removal
		local queenremoval = (contents[slot].count - 1) 						---How many queens are we removing?
		world.containerConsumeAt(entity.id(), slot - 1, queenremoval)  					---PEACE OUT, YA QUEENS -- slot-1 because of indexing differences (Lua's from 1 v. Starbound internal from 0)
		world.spawnItem(queenname, object.toAbsolutePosition({ 1, 2 }), queenremoval)			--- Oh, hi. Why are you on the ground? SHE THREW YOU OUT? THAT BITCH!
	end
end


function beeSting()
	if math.random(100) < 100 * self.beeStingChance then
		local location = entity.position()
		if self.beeStingOffset then
			world.spawnProjectile("stingstatusprojectile", { location[1] + self.beeStingOffset[1], location[2] + self.beeStingOffset[2]}, entity.id())
		else
			world.spawnProjectile("stingstatusprojectile", location, entity.id())
		end
	end
end

function flowerCheck()
	local flowers
	self.flowerPower = self.beePower
	local noFlowersYet = self.flowerPower

	for i, p in pairs(self.config.flowers) do
		flowers = world.objectQuery(entity.position(), 80, {name = p})
		if flowers ~= nil then
			self.flowerPower = self.flowerPower + math.ceil(math.sqrt(#flowers) / 2)
		end
	end

	if self.flowerPower == noFlowersYet then
		self.flowerPower = -1
	elseif self.flowerPower >= 60 then
		self.flowerPower = 60
	end

	if self.beeType == 'honey'
		then self.flowerPower = self.flowerPower*1.5
	end

	return self.flowerPower --sees no flowers but is working anyway?
end

function vegetableCheck()
	local vegetables
	self.vegetablePower = self.beePower
	local noVegetablesYet = self.vegetablePower

	for i, p in pairs(self.config.vegetables) do
		vegetables = world.objectQuery(entity.position(), 80, {name = p})
		if vegetables ~= nil then
			self.vegetablePower = self.vegetablePower + math.ceil(math.sqrt(#vegetables) / 2)
		end
	end

	if self.vegetablePower == noVegetablesYet then
		self.vegetablePower = -1
	elseif self.vegetablePower >= 60 then
		self.vegetablePower = 60
	end

	if self.beeType == 'squash'
		then self.vegetablePower = self.vegetablePower*1.2
	elseif self.beeType == 'honey'
		then self.vegetablePower = self.vegetablePower*.5
	end

	return self.vegetablePower
end

function fruitCheck()
	local fruits
	self.fruitPower = self.beePower
	local noFruitYet = self.fruitPower

	for i, p in pairs(self.config.fruits) do
		fruits = world.objectQuery(entity.position(), 80, {name = p})
		if fruits ~= nil then
			self.fruitPower = self.fruitPower + math.ceil(math.sqrt(#fruits) / 2)
		end
	end

	if self.fruitPower == noFruitYet then
		self.fruitPower = -1
	elseif self.fruitPower >= 60 then
		self.fruitPower = 60
	end

	if self.beeType == 'sweat'
		then self.fruitPower = self.fruitPower*1.2
	end

	return self.fruitPower
end

function pollinationCheck()
	fruitCheck()
	vegetableCheck()
	flowerCheck()

	self.beePower = self.flowerPower + self.vegetablePower + self.fruitPower

	if self.beePower <= -1
		then self.beePower = -1
	elseif self.beePower >= 60
		then self.beePower = 60
	end

	return self.beePower

end


function deciding()
	if self.beePower < 0 then
		return
	end

	local location = entity.position()
	world.debugText("H:" .. (self.spawnHoneyCooldown or 'nil').. "/I:" .. (self.spawnItemCooldown or 'nil') .. "/D:" .. (self.spawnDroneCooldown or 'nil') .. "/B:" .. (self.spawnBeeCooldown or 'nil'),{location[1],location[2]-0.5},"orange")
	-- object.say("H:" .. self.spawnHoneyCooldown .. "/I:" .. self.spawnItemCooldown .. "/ D:" .. self.spawnDroneCooldown .. "/B:" .. self.spawnBeeCooldown)

	-- counting down and looking for events like spawning a bee, an item or honey
	-- also applies the effects if something has to spawn (increasing cooldown, slowing things down)
	-- if any brake is false, no spawn and no cooldown for that type

	-- FIXME: beeModifier?
	if self.spawnBeeBrake then
		if self.spawnBeeCooldown <= 0 then
			self.spawnBeeBrake = self.spawnBeeBrake * 2    	---each time a bee is spawned, the next bee takes longer, unless the world reloads. (Reduce Lag)
			self.doBees = true
			self.spawnBeeCooldown = ( self.spawnBeeBrake * self.spawnDelay ) - self.honeyModifier   ----these self.xModifiers reduce the cooldown by a static amount, only increased by frames.
		else
			self.doBees = false
			self.spawnBeeCooldown = self.spawnBeeCooldown - self.beePower * self.beePowerScaling      ---beepower sets how much the cool down reduces each tick.
		end
	end

	if self.spawnDroneBrake then
		if self.spawnDroneCooldown <= 0 then
			-- self.spawnDroneBrake = self.spawnDroneBrake + 10
			self.doDrones = true
			self.spawnDroneCooldown = ( self.spawnDelay * self.spawnDroneBrake ) - self.droneModifier
		else
			self.doDrones = false
			self.spawnDroneCooldown = self.spawnDroneCooldown - self.beePower * self.beePowerScaling
		end
	end

	if self.spawnItemBrake then
		if self.spawnItemCooldown <= 0 then
			-- self.spawnItemBrake = self.spawnItemBrake + 10
			self.doItems = true
			self.spawnItemCooldown = ( self.spawnDelay * self.spawnItemBrake ) - self.itemModifier
		else
			self.doItems = false
			self.spawnItemCooldown = self.spawnItemCooldown - self.beePower * self.beePowerScaling
		end
	end

	if self.spawnHoneyBrake then
		if self.spawnHoneyCooldown <= 0 then
			-- self.spawnHoneyBrake = self.spawnHoneyBrake + 10
			self.doHoney = true
			self.spawnHoneyCooldown = ( self.spawnDelay * self.spawnHoneyBrake ) - self.honeyModifier
		else
			self.doHoney = false
			self.spawnHoneyCooldown = self.spawnHoneyCooldown - self.beePower * self.beePowerScaling
		end
	end
end


function checkAntimiteFrames ()
	-- then we check how many mite-killing frames are present
	self.totalFrames = 0
	for _,item in pairs(world.containerItems(entity.id())) do
		if self.antimiteFrames[item.name] then
			self.totalFrames= self.totalFrames + item.count
		end
	end
end

function updateTotalMites()
    self.totalMites = 0
    contents = world.containerItems(entity.id())
    if not contents then return end

    for _,item in pairs(contents) do
        if item.name=="vmite" then
            self.totalMites= (self.totalMites + item.count) - self.miteReduction + self.mitePenalty
        end
    end
end

function miteInfection()
    local vmiteFitCheck = world.containerItemsCanFit(entity.id(), { name= "vmite", count = 1, data={}})   --see if the container has room for more mites
    local fmiteFitCheck = world.containerItemsCanFit(entity.id(), { name= "firemite", count = 1, data={}})

    checkAntimiteFrames()

    -- mite settings get applied
    local baseMiteChance = 0.4 + math.random(2) + (self.totalMites/10)
    if baseMiteChance > 100 then baseMiteChance = 100 end

    local baseMiteReproduce = (1 + (self.totalMites /40))
    local baseMiteKill = 2 * (self.totalFrames /24)
    if baseMiteKill < 1 then baseMiteKill = 1 end

    local baseDiceRoll = math.random(200)
    local baseSmallDiceRoll = math.random(100)
    local baseLargeDiceRoll = math.random(1000)

     --Infection stops spreading if the frame is an anti-mite frame present. It this is the case, we also roll to see if we get a bugshell when we kill the mite.
    if self.antimite then
        world.containerConsume(entity.id(), { name= "vmite", count = math.min(baseMiteKill,self.totalMites), data={}})
        if baseSmallDiceRoll < 10 and self.totalMites > 12 then   --chance to spawn bugshell when killing mites
          world.containerAddItems(entity.id(), { name="bugshell", count = baseMiteKill/2, data={}})
        end
    elseif (self.totalMites >= 360) and (baseDiceRoll < baseMiteChance) then
        --animator.playSound("addMite")
    elseif (self.totalMites >= 10) and (baseSmallDiceRoll < baseMiteChance *4) and (vmiteFitCheck > 0) then
        transferUtil.unloadSelfContainer()
        world.containerAddItems(entity.id(), { name="vmite", count = baseMiteReproduce, data={}})
        self.totalMites = self.totalMites + baseMiteReproduce
        self.beePower = self.beePower - (1 + self.totalMites/20)
    elseif (baseDiceRoll < baseMiteChance) and (vmiteFitCheck > 0) then
        transferUtil.unloadSelfContainer()
        world.containerAddItems(entity.id(), { name="vmite", count = baseMiteReproduce, data={}})
        self.totalMites = self.totalMites + baseMiteReproduce
        self.beePower = self.beePower - (1 + self.totalMites/20)
    end
end

function miteKillsBee()
        local queen, drone = getEquippedBees()
        if baseSmallDiceRoll == 0 then
          world.containerConsume(entity.id(), { name= queen, count = 1, data={}})
        elseif baseSmallDiceRoll < 10 then
          world.containerConsume(entity.id(), { name= drone, count = baseMiteReproduce, data={}})
        end
end

function daytimeCheck()
	earlyday = world.timeOfDay() < 0.25 or world.type() == 'playerstation'
	daytime = world.timeOfDay() < 0.5 or world.type() == 'playerstation'
	night = world.timeOfDay() > 0.5 or world.type() == 'playerstation'
	midday = world.timeOfDay() > 0.125 and world.timeOfDay() < 0.375 or world.type() == 'playerstation'
	midnight = world.timeOfDay() > 0.625 and world.timeOfDay() < 0.875 or world.type() == 'playerstation' --we made day earlier
end

function setAnimationState()
	if self.beePower < 0 then
		animator.setAnimationState("bees", "off")
	elseif self.beeActiveWhen == "day" then
		animator.setAnimationState("bees", daytime and "on" or "off")
	elseif self.beeActiveWhen == "earlyday" then
		animator.setAnimationState("bees", earlyday and "on" or "off")
	elseif self.beeActiveWhen == "night" then
		animator.setAnimationState("bees", night and "on" or "off")
	elseif self.beeActiveWhen == "midday" then
		animator.setAnimationState("bees", midday and "on" or "off")
	elseif self.beeActiveWhen == "midnight" then
		animator.setAnimationState("bees", midnight and "on" or "off")
	else
		animator.setAnimationState("bees", self.beeActiveWhen == "always" and "on" or "off")
	end
end


function update(dt)
	updateTotalMites()

    if not deltaTime or (deltaTime > 1) then
        deltaTime=0
		if self.totalMites and self.totalMites>0 then
			transferUtil.unloadSelfContainer()
		else
			transferUtil.loadSelfContainer()
		end
    else
        deltaTime=deltaTime+dt
    end
	contents = world.containerItems(entity.id())
	daytimeCheck()

	if not contents[self.queenSlot] or not contents[self.droneSlot] then
		-- removing bees will reset the timers
		if self.beePower ~= 0 then
			reset()
		else
			animator.setAnimationState("bees", "off")
			return
		end
	end

	frame() 	--Checks to see if a frame in installed.
	pollinationCheck()   -- combine fruit, vegetable, and flower check
	deciding()

	if not self.doBees and not self.doItems and not self.doHoney and not self.doDrones then
		-- no need to search for the bees if there is nothing to do with them
		if self.beePower > 0 then
			self.beePower = 0
		elseif self.beePower < 0 then
			animator.setAnimationState("bees", "off")
			return
		end
	end

	miteInfection()	-- Try to spawn mites.

	if not workingBees() then
		-- If bees aren't a match, check to see if the bee types are meant for breeding.
		breedingBees()
	end

	setAnimationState()
end


function chooseMinerHoney(config)
	if not self.doHoney then return nil end

	-- Pick a type at random from those found.
	local minerFrames = 0
	local types = {}
	for frame, count in pairs(self.combs) do
		minerFrames = minerFrames + count
		if count > 0 then table.insert(types, frame) end
	end

	if minerFrames == 0 then return nil end

	-- boosted chance of spawning a comb: extra chance is 50% or 75% of the difference between default and 1
	local chance = config.chance or DEFAULT_HONEY_CHANCE
	chance = chance + (1 - chance) * (minerFrames * 2 - 1) / (minerFrames * 2)

	-- generally, chance of a special ore comb is 1/3 if 1 miner-affecting frame or 1/2 if 2
	-- TODO: nerf diamond comb production
	if math.random() > 1 / (4 - minerFrames) then
--		sb.logInfo('may spawn minercomb, chance = %s', chance)
		return { chance = chance }
	end

	-- equal chance of which frame affects the comb type
	-- some may unsuccessfully affect the comb type; in that case, the default type is produced
--	sb.logInfo('may spawn frame-affected comb, chance = %s', chance)
	local type = types[math.random(#types)]
	if self.config.oreSuccess[type] and math.random() > self.config.oreSuccess[type] then
		type = nil
	end
	return { type = type, chance = chance }
end


function chooseMinerOffspring(config)
	if self.mutationIncrease == 0 then
	  return nil
	end

	if math.random() > self.mutationIncrease then
	--sb.logInfo('may spawn miner bees')
		return nil
	end

	--sb.logInfo('may spawn strange bees')
	local threat = world.threatLevel() or 1
	local chance = config.chance or DEFAULT_HONEY_CHANCE
	if (math.random(100) <= 10 * (chance + self.mutationIncrease)) then
	  world.spawnMonster("fuevilbee", object.toAbsolutePosition({ 0, 3 }), { level = threat, aggressive = true })
	elseif (math.random(100) <= 5 * (chance + self.mutationIncrease)) then
	  world.spawnMonster("elderbee", object.toAbsolutePosition({ 0, 3 }), { level = threat, aggressive = true })
	elseif (math.random(100) <= 2 * (chance + self.mutationIncrease)) then
	  world.spawnMonster("fearmoth", object.toAbsolutePosition({ 0, 3 }), { level = threat, aggressive = true })
	end

	return { type = 'radioactive', chance = config.chance, bee = (config.bee or 1) * 1.1, drone = (config.drone or 1) * 0.9 } -- tip a little more in favour of world over hive

end


function workingBees()

	local type, config

	local queen, drone = getEquippedBees()
	findBeeType()

	if queen == drone and self.config.spawnList[queen] then
		local config = self.config.spawnList[queen]
		if self.beeType == 'carpenter'
			then self.beeActiveWhen = 'earlyday'
		elseif self.beeType == 'mason'
			then self.beeActiveWhen = 'night'
		elseif self.beeType == 'leafcutter'
			then self.beeActiveWhen = 'midday'
		elseif self.beeType == 'squash'
			then self.beeActiveWhen = 'earlyday'
		elseif self.beeType == 'plasterer'
			then self.beeActiveWhen = 'midnight'
		else
			self.beeActiveWhen = 'day'
		end

		if world.type() == "playerstation"
			then self.beeActiveWhen = "always" end

--		sb.logInfo ('Checking ' .. queen .. ' (' .. when .. ' / ' .. notnow .. ')')

		if animator.animationState("bees") == 'on' or world.type() == "playerstation" then -- strictly, when == 'always' or == now

			if self.doHoney then
				-- read config; call functions returning config if specified
				local honey = config.honey and (self.doHoney and config.honey.func and self.functions[config.honey.func] and self.functions[config.honey.func](config.honey, queen) or config.honey) or {}

				-- get type and chances, handling fallbacks
				local honeyType   = honey.type       or (config.honey     and config.honey.type      ) or queen
				local honeyChance = honey.chance     or (config.honey     and config.honey.chance    ) or DEFAULT_HONEY_CHANCE

				trySpawnHoney(honeyChance, honeyType)
			end

			local function doBeeOrDrone(type, spawnFunc)
				-- read config; call functions returning config if specified
				local offspring = config.offspring and (config.offspring.func and self.functions[config.offspring.func] and self.functions[config.offspring.func](config.offspring, queen, type) or config.offspring) or {}

				-- get type and chances, handling fallbacks
				local chance = offspring.chance or (config.offspring and config.offspring.chance) or DEFAULT_OFFSPRING_CHANCE
				chance       = chance * (offspring[type] or (config.offspring and config.offspring[type]) or 1)

				spawnFunc(chance, offspring.type or queen)
			end

			if self.doBees   then doBeeOrDrone('bee',   trySpawnBee  ) end
			if self.doDrones then doBeeOrDrone('drone', trySpawnDrone) end

			if config.items and self.doItems then
				for item, chance in pairs(config.items) do
					trySpawnItems(chance, item)
				end
			end

			if config.sting then beeSting() end

			expelQueens(queen)  -- bitches this be MY house. (Kicks all queens but 1 out of the apiary)
		end

		-- found a match, so just return now indicating success
		return true
	end

	return false -- we have not found a match; returning false so we can run breedingBees() in main()
end


function breedingBees()
	if daytime then
		local bee1Type = contents[self.queenSlot] and stripQueenDrone(contents[self.queenSlot].name)
		local bee2Type = contents[self.droneSlot] and stripQueenDrone(contents[self.droneSlot].name)
		local species = (bee1Type and bee2Type) and (self.config.breeding[bee1Type .. bee2Type] or self.config.breeding[bee2Type .. bee1Type])

		if species ~= nil then
--			sb.logInfo ('Checking ' .. bee1Type .. ' + ' .. bee2Type)
--			animator.setAnimationState("bees", "on")
			trySpawnHoney(0.2, "normal")
			trySpawnMutantBee(0.25, species)
			trySpawnMutantDrone(0.20, species)
			expelQueens(bee1Type)
			expelQueens(bee2Type)
			self.beeActiveWhen = "day"
			return true
		end
	end

        miteInfection() -- additional chance for infection when breeding

	self.beeActiveWhen = "unknown"
	self.beePower = -1
	return false
end
