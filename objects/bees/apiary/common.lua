require "/scripts/kheAA/transferUtil.lua"

local contents
local deltaTime=0
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
NEW PROPERTIES

some way to check Fruit, Vegetable or Flower based on bee types preferences. Production of non-preferenced pollination is 25%, rather than 100%.

queenAge = the older the queen, the better the hive gets. This is added to production totals. Max additional output is +5. Add +1 age per day (24 hours real-time, not game time). Regains 1HP per day if safe.
queenLifespan = the total number of days a queen survives before dying and spawning a new queen to take over. This varies on breed.
queenHealth = the older the queen, the more HP she has. Mite infestations will reduce her health and potentially kill her.

mutationIncrease increases with Queen age as well, meaning that the older the queen the more likely the hive is to spawn weird mutations


droneTotal = the total drones impact the total output of the hive. This total is added as (droneTotal). This total is added to beePower and has no cap.

isFavoredEnvironment? = the environment is favorable to the bee, and no penalty is applied. If false, production is reduced and Mite infestation rates increase substantially (biome tier x default rate). 
Biome threat level is done in damage to the queens HP (per game day)

frameCount = total frames adds to total production. Maximum is 50 frames. This is added to beePower. Should run in frame()

miteModifier = when bees dont do well in environments, mites increase chance. However, with safeguards in check these totals can be mitigated. The number of Mite frames will increase mite-kill rates.
miteCount = when mite counts are higher, we increase the effect of mites on the hive. Each Mite reduces BeePower by 1 to 2. This penalty is doubled in unfavorable biomes.

--]



function init()
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
		self.config = root.assetJson('/objects/bees/apiaries.config')	-- common apiaries configuration
		self.functions = { chooseMinerHoney = chooseMinerHoney, chooseMinerOffspring = chooseMinerOffspring }

		reset()
		return true
	end
	return false
end


function reset()   ---When bees are not present, this sets a slightly increased timer for when bees are added again.
	if self.spawnBeeBrake   then self.spawnBeeCooldown   = self.spawnBeeBrake   * 2 end
	if self.spawnItemBrake  then self.spawnItemCooldown  = self.spawnItemBrake  * 2 end
	if self.spawnHoneyBrake then self.spawnHoneyCooldown = self.spawnHoneyBrake * 2 end
	if self.spawnDroneBrake then self.spawnDroneCooldown = self.spawnDroneBrake * 2 end
	self.beePower = 0
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
		-- Does not matter in which slot the queen or the drone is
		local count

		if queen.name == queenName .. 'queen' and drone.name == droneName .. 'drone' then
--			sb.logInfo ('Found ' .. drone.count .. ' drones')
			count = drone.count
		elseif queen.name == queenName .. 'drone' and drone.name == droneName .. 'queen' then
--			sb.logInfo ('Found ' .. queen.count .. ' drones in queen slot')
			queenName, droneName = droneName, queenName -- ensure that we return queen, drone when content is drone, queen
			count = queen.count
		end

		if count then
			self.beePower = math.ceil(math.sqrt(count) + 10)  ---Beepower = cooldown reduction rate. At 500ms scriptDelta, and with 20 beePower, it takes 5 seconds to reduce a 200 cooldown to 0.
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
--	if self.doBees then sb.logInfo ('Maybe spawning a bee') end
	if self.doBees and math.random(100) <= 100 * chance and spaceForBees() then
		world.spawnMonster(type .. "bee", object.toAbsolutePosition({ 2, 3 }), { level = 1 })	
		self.doBees = false
	end
end


function trySpawnMutantBee(chance,type)
--	if self.doBees then sb.logInfo ('Maybe spawning a mutant bee') end
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
--	if self.doDrones then sb.logInfo ('Maybe spawning some drones') end
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
--	if self.doDrones then sb.logInfo ('Maybe spawning some mutant drones') end
	if self.doDrones and math.random(100) <= 100 * (chance + self.mutationIncrease) then
		world.containerAddItems(entity.id(), { name=type .. "drone", count = amount or 1, data={}})
		self.doDrones = false -- why was this doItems?
	end
end


function trySpawnItems(chance,type,amount)
--	if self.doItems then sb.logInfo ('Maybe spawning items: ' .. type) end
	-- analog to trySpawnBee() for items (like goldensand)
	if self.doItems and math.random(100) <= 100 * chance then
		world.containerAddItems(entity.id(), { name=type, count = amount or 1, data={}})
		self.doItems = false
	end
end


function trySpawnHoney(chance,honeyType,amount)
--	if self.doHoney then sb.logInfo ('Maybe spawning honey: ' .. honeyType) end
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
	if contents[self.queenSlot].name == queenLocate then	---is queen in slot17? (Top bee slot)
		slot = self.queenSlot
	elseif contents[self.droneSlot].name == queenLocate then	---is queen in slot17? (Top bee slot)
		slot = self.droneSlot
	end

	if slot and contents[slot].count > 1 then			---how many queens, exactly?
		local queenname = contents[slot].name		---sets the variable queenname to be use for queen removal
		local queenremoval = (contents[slot].count - 1) ---How many queens are we removing?
		--world.containerConsume(entity.id(), {name = queenname, count = queenremoval, data={}})  ---PEACE OUT, YA QUEENS --could take from storage, not just the queen slot
		world.containerConsumeAt(entity.id(), slot - 1, queenremoval)  ---PEACE OUT, YA QUEENS -- slot-1 because of indexing differences (Lua's from 1 v. Starbound internal from 0)
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
	local noFlowersYet = self.beePower 			---- Check the initial "beePower" before flowers...

	for i, p in pairs(self.config.flowers) do
		flowers = world.objectQuery(entity.position(), 80, {name = p})
		if flowers ~= nil then
			self.beePower = self.beePower + math.ceil(math.sqrt(#flowers) / 2)
		end
	end
	
	if self.beePower == noFlowersYet then
		self.beePower = -1				--- If there are no flowers for the bees... they can't do anything.
	elseif self.beePower >= 60 then
		self.beePower = 60
	end

	local beePowerSay = "FC:bP = " .. self.beePower
	local location = entity.position()
	world.debugText(beePowerSay,{location[1],location[2]+1.5},"orange")
	-- object.say(beePowerSay)
end

function vegetableCheck()
	local vegetables
	local noFlowersYet = self.beePower 			

	for i, p in pairs(self.config.vegetables) do
		vegetables = world.objectQuery(entity.position(), 80, {name = p})
		if vegetables ~= nil then
			self.beePower = self.beePower + math.ceil(math.sqrt(#vegetables) / 2)
		end
	end	
	
	if self.beePower == noFlowersYet then
		self.beePower = -1			
	elseif self.beePower >= 60 then
		self.beePower = 60
	end

	local beePowerSay = "FC:bP = " .. self.beePower
	local location = entity.position()
	world.debugText(beePowerSay,{location[1],location[2]+1.5},"orange")
	-- object.say(beePowerSay)
end

function fruitCheck()
	local fruits
	local noFlowersYet = self.beePower 			

	for i, p in pairs(self.config.fruits) do
		fruits = world.objectQuery(entity.position(), 80, {name = p})
		if fruits ~= nil then
			self.beePower = self.beePower + math.ceil(math.sqrt(#fruits) / 2)
		end
	end
	
	if self.beePower == noFlowersYet then
		self.beePower = -1				
	elseif self.beePower >= 60 then
		self.beePower = 60
	end

	local beePowerSay = "FC:bP = " .. self.beePower
	local location = entity.position()
	world.debugText(beePowerSay,{location[1],location[2]+1.5},"orange")
	-- object.say(beePowerSay)
end


function deciding()
	if self.beePower < 0 then   ---if the apiary doesn't have bees, then stop.
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
--			sb.logInfo('Chance of spawning a bee')
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
--			sb.logInfo('Chance of spawning a drone')
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
--			sb.logInfo('Chance of spawning an item')
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
--			sb.logInfo('Chance of spawning honey')
			self.spawnHoneyCooldown = ( self.spawnDelay * self.spawnHoneyBrake ) - self.honeyModifier
		else
			self.doHoney = false
			self.spawnHoneyCooldown = self.spawnHoneyCooldown - self.beePower * self.beePowerScaling
		end
	end
end


function miteInfection()   ---Random mite infection.
	local vmiteFitCheck = 	world.containerItemsCanFit(entity.id(), { name= "vmite", count = 1, data={}})     ---see if the container has room for more mites
	local vmiteInfectedCheck = 	world.containerConsume(entity.id(), { name= "vmite", count = 1, data={}}) ---see if the container is infected with mites

	if math.random(100) < 6 then
		if vmiteFitCheck == true then
			world.containerAddItems(entity.id(), { name="vmite", count = 1, data={}})  		  -- add the mite
		end
	end

	if self.antimite then
		---Infection stops spreading if the frame is an anti-mite frame or magma frame.
		world.containerConsume(entity.id(), { name= "vmite", count = 10, data={}})
		world.containerConsume(entity.id(), { name= "vmite", count = 5, data={}})
		world.containerConsume(entity.id(), { name= "vmite", count = 2, data={}})
		world.containerConsume(entity.id(), { name= "vmite", count = 1, data={}})
	elseif vmiteInfectedCheck == true then
		world.containerAddItems(entity.id(), { name="vmite", count = 31, data={}})
		world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
		world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
		world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
		world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
		world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
		world.containerAddItems(entity.id(), { name="vmite", count = 60, data={}})
		self.beePower = -1    										   -- penalty gets applied here to production power. this needs to not be a flat -1, however, and instead penalize based on total mites present
--		sb.logInfo ('Hive is infected')
	end
end


function daytimeCheck()
	daytime = world.timeOfDay() < 0.5 or world.type() == 'playerstation' -- true if daytime, otherwise false. Player space stations are an exception to the rule.
end


function setAnimationState()
	if self.beePower < 0 then
		animator.setAnimationState("bees", "off")
	elseif beeActiveWhen == "day" then
		animator.setAnimationState("bees", daytime and "on" or "off")
	elseif beeActiveWhen == "night" then
		animator.setAnimationState("bees", daytime and "off" or "on")
	else
		animator.setAnimationState("bees", beeActiveWhen == "always" and "on" or "off")
	end
end


function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
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

	frame() 							---Checks to see if a frame in installed.
	flowerCheck()    						--- checks flowers

	--[
	************************ NEW. This checks bee preference against what crops are nearby
	if beeType = flowerBee then
		flowerCheck()  
	elseif beeType = vegetableBee then
		vegetableCheck()
	elseif beeType = fruitBee then
	        fruitCheck()							
	end
	--]
	
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

	miteInfection()		--- Try to spawn mites.

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
--		sb.logInfo('may spawn miner bees')
		return nil
	end
	
--	sb.logInfo('may spawn radioactive bees')
                local threat = world.threatLevel() or 1
                local chance = config.chance or DEFAULT_HONEY_CHANCE
		if (math.random(100) <= 20 * (chance + self.mutationIncrease)) then
		  world.spawnMonster("fuevilbee", object.toAbsolutePosition({ 0, 3 }), { level = threat, aggressive = true })
		elseif (math.random(100) <= 10 * (chance + self.mutationIncrease)) then
		  world.spawnMonster("elderbee", object.toAbsolutePosition({ 0, 3 }), { level = threat, aggressive = true })
		elseif (math.random(100) <= 5 * (chance + self.mutationIncrease)) then
		  world.spawnMonster("fearmoth", object.toAbsolutePosition({ 0, 3 }), { level = threat, aggressive = true })
		end
	return { type = 'radioactive', chance = config.chance, bee = (config.bee or 1) * 1.1, drone = (config.drone or 1) * 0.9 } -- tip a little more in favour of world over hive
	
end


function workingBees()

	local type, config
	local notnow = daytime and 'night' or 'day'

	local queen, drone = getEquippedBees()

	if queen == drone and self.config.spawnList[queen] then
		local config = self.config.spawnList[queen]
		local when = config.active or 'day'
--		sb.logInfo ('Checking ' .. queen .. ' (' .. when .. ' / ' .. notnow .. ')')

		
		if when ~= notnow or world.type() == "playerstation" then -- strictly, when == 'always' or == now
			if when ~= notnow then 
				beeActiveWhen = when 
				else 
				beeActiveWhen = "always" 
			end

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
			beeActiveWhen = "day"
			return true
		end
	end

	beeActiveWhen = "unknown"
	self.beePower = -1
	return false
end
