local contents

function init(virtual)
	if virtual == true then return end

	animator.setAnimationState("bees", "off")

	if not self.spawnDelay or not contents then
		self.queenSlot = config.getParameter ("queenSlot")				-- Apiary inventory slot number (indexed from 1)
		self.droneSlot = config.getParameter ("droneSlot")				--
		self.frameSlots = config.getParameter ("frameSlots")			--

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
	if item then
		name = item.name
		-- Production quantity modifier frames
		-- Large apiary and scented apiary used 6, 8, 0.02. 0.05 instead of 15, 25, 0.04, 0.08.
		if     name == "basicframe" then
			mods.honeyModifier = (mods.honeyModifier or 0) + 15
		elseif name == "sweetframe" then
			mods.honeyModifier = (mods.honeyModifier or 0) + 25
		elseif name == "provenframe" then
			mods.itemModifier = (mods.itemModifier or 0) + 15
		elseif name == "durasteelframe" then
			-- this probably needs to be on a new frame type
			mods.itemModifier = (mods.itemModifier or 0) + 25
		elseif name == "scentedframe" then
			mods.droneModifier = (mods.droneModifier or 0) + 15
		elseif name == "uraniumframe" then
			mods.mutationIncrease = (mods.mutationIncrease or 0) + 0.04
		elseif name == "plutoniumframe" then
			mods.mutationIncrease = (mods.mutationIncrease or 0) + 0.08
		--elseif name == "bees_royalframe" then -- no such item
		elseif name == "feroziumframe" then
			-- FIXME: beeModifier?
			mods.droneModifier = (mods.droneModifier or 0) + 10
			mods.honeyModifier = (mods.honeyModifier or 0) + 10
			mods.itemModifier  = (mods.itemModifier  or 0) + 10
		-- Day/night modifiers
		elseif name == "solarframe" then
			mods.forceTime = (mods.forceTime or 0) + 1 -- +ve to force day
		elseif name == "eclipseframe" then
			mods.forceTime = (mods.forceTime or 0) - 1 -- -ve to force night
		end
		-- Miner bees' modifiers
		if     name == "copperframe" then
			mods.combs.copper = (mods.combs.copper or 0) + 1
		elseif name == "silverframe" then
			mods.combs.silver = (mods.combs.silver or 0) + 1
		elseif name == "goldframe" then
			mods.combs.gold = (mods.combs.gold or 0) + 1
		elseif name == "diamondframe" then
			mods.combs.precious = (mods.combs.precious or 0) + 1
		elseif name == "ironframe" then
			mods.combs.iron = (mods.combs.iron or 0) + 1
		elseif name == "titaniumframe" then
			mods.combs.titanium = (mods.combs.titanium or 0) + 1
		elseif name == "tungstenframe" then -- used to work only in large apiary. Enabled everywhere as per description.
			mods.combs.tungsten = (mods.combs.tungsten or 0) + 1
		elseif name == "durasteelframe" then -- used to work in large or scented apiaries. Enabled everywhere.
			mods.combs.durasteel = (mods.combs.durasteel or 0) + 1
		elseif name == "amite" then
			mods.antimite = true
--		else return -- DEBUG avoidance
		end
--		sb.logInfo ('apiary ' .. entity.id() .. ': found ' .. name)
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


function trySpawnBee(chance,type)
	-- tries to spawn bees if we haven't in this round
	-- Type is normally things "normal" or "bone", as the code inputs them in workingBees() or breedingBees(), this function uses them to spawn bee monsters. "normalbee" for example.
	-- chance is a float value between 0.00 (will never spawn) and 1.00 (will always spawn)
--	if self.doBees then sb.logInfo ('Maybe spawning a bee') end
	if self.doBees and math.random(100) <= 100 * chance then
		world.spawnMonster(type .. "bee", object.toAbsolutePosition({ 2, 3 }), { level = 1 })
		self.doBees = false
	end
end


function trySpawnMutantBee(chance,type)
--	if self.doBees then sb.logInfo ('Maybe spawning a mutant bee') end
	if self.doBees and math.random(100) <= 100 * (chance + self.mutationIncrease) then
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
--	if self.doDrone then sb.logInfo ('Maybe spawning some drones') end
	if self.doDrone and math.random(100) <= 100 * chance then
		local bonus, reduce = droneStarter()
		amount = amount or (math.random(2) + bonus)
		world.containerAddItems(entity.id(), { name=type .. "drone", count = amount, data={}})
		self.doDrone = false -- why was this doItems?
		if reduce then
			world.containerConsume(entity.id(), {name =type .. "drone", count = math.random(5), data={}})
		end
	end
end


function trySpawnMutantDrone(chance,type,amount)
--	if self.doDrone then sb.logInfo ('Maybe spawning some mutant drones') end
	if self.doDrone and math.random(100) <= 100 * (chance + self.mutationIncrease) then
		world.containerAddItems(entity.id(), { name=type .. "drone", count = amount or 1, data={}})
		self.doDrone = false -- why was this doItems?
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
		world.containerAddItems(entity.id(), { name=honeyType .. "comb", count = amount, data={}})
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
			world.spawnProjectile("stingstatusprojectile", { location[1] + self.beeStingOffset[1], location[2] + self.beeStingOffset[2], entity.id() })
		else
			world.spawnProjectile("stingstatusprojectile", location)
		end
	end
end


function flowerCheck()
	local flowers
	local noFlowersYet = self.beePower 			---- Check the initial "beePower" before flowers...

	for i, p in pairs({
		-- Standard
		"giantflower1", "giantflower2", "giantflower3", "giantflower4",
		"springbush1", "springbush2", "springbush3", "springbush4", "springbush5", "springbush6",
		"flowerred", "floweryellow", "flowerblue",
		-- Frackin' Universe
		"flowerblack", "flowerbrown", "flowergreen", "flowergrey",
		"flowerorange", "flowerpink", "flowerpurple", "flowerwhite",
		"flowerspring",
		"flowerorchid", "flowerorchid2", "flowerorchid3",
		"energiflowerseed",
		"floralytplantseed",
		"goldenglowseed",
		"haleflowerseed",
		"itaseed",
		"nissseed",
		"wubstemseed",
		"miraclegrassseed",
		"vanusflowerseed",
		"beeflower"
	}) do
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
	world.debugText(beePowerSay,{location[1],location[2]-0.5},"orange")
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
			self.doDrone = true
--			sb.logInfo('Chance of spawning a drone')
			self.spawnDroneCooldown = ( self.spawnDelay * self.spawnDroneBrake ) - self.droneModifier
		else
			self.doDrone = false
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
---see if the container has room for more mites
	local vmiteFitCheck = 	world.containerItemsCanFit(entity.id(), { name= "vmite", count = 1, data={}})
---see if the container is infected with mites
	local vmiteInfectedCheck = 	world.containerConsume(entity.id(), { name= "vmite", count = 1, data={}})

---initial infection. with a 500ms polling rate, this runs at once per 60 minutes per apiary, an infection should happen.
---The previous comment doesn't actually make sense. It's not your imagination. -renbear
	if math.random(1000) < 6 then
		if vmiteFitCheck == true then
			world.containerAddItems(entity.id(), { name="vmite", count = 64, data={}})
		end
	end

	if self.antimite then
		---Infection stops spreading if the frame is the anti-mite frame.
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
		self.beePower = -1
--		sb.logInfo ('Hive is infected')
	end
end


function daytimeCheck()
	daytime = world.timeOfDay() < 0.5 -- true if daytime
end


function setAnimationState()
	if self.beePower < 0 then
--		sb.logInfo ('OFF')
		animator.setAnimationState("bees", "off")
	elseif beeActiveWhen == "day" then
--		sb.logInfo ('Day: ' .. (daytime and "on" or "off"))
		animator.setAnimationState("bees", daytime and "on" or "off")
	elseif beeActiveWhen == "night" then
--		sb.logInfo ('Night: ' .. (daytime and "off" or "on"))
		animator.setAnimationState("bees", daytime and "off" or "on")
	else
--		sb.logInfo ('Always? ' .. (beeActiveWhen or ''))
		animator.setAnimationState("bees", beeActiveWhen == "always" and "on" or "off")
	end
end


function update(dt)
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

	frame()   ---Checks to see if a frame in installed.
	flowerCheck()
	deciding()

	if not self.doBees and not self.doItems and not self.doHoney and not self.doDrone then
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


function spawnMinerSpecialOre()
	-- Pick a type at random from those found and spawn it.
	local types = {}
	for frame, count in pairs(self.combs) do
		if count > 0 then table.insert(types, frame) end
	end
	if #types > 0 then trySpawnHoney(1, types[math.random(#types)]) end
end


function spawnMinerSpecialsEarly()
	if self.doHoney then
		-- Do we have more than one frame slot containing miner-affecting frames?
		-- If so, (n-1)/(n+2) probability of spawning early.
		-- For two frames, this works out at 0.25 (25%), reducing the effective chance of Deep Earth Comb to 40% (given the default 60%) and the late chance of a metal ore comb to 35%.
		-- Effectively, a 60% chance of a metal ore and, within that, an equal chance for each type for which a frame is present.
		local minerFrames = 0
		for frame, count in pairs(self.combs) do
			minerFrames = minerFrames + count
		end
		if minerFrames > 1 and math.random() <= (minerFrames - 1) / (minerFrames + 2) then
			spawnMinerSpecialOre()
		end
	end
end


function spawnMinerSpecialsLate()
	if self.doHoney then spawnMinerSpecialOre() end

	if self.mutationIncrease > 0 then
		trySpawnMutantBee  (0.16, "radioactive")
		trySpawnMutantDrone(0.12, "radioactive")
	end
end


function workingBees()
	beeSpawnList = {
--[[
		class = {
			active = one of "day", "night", "always"
			honeyType = TYPE
			honeyChance = CHANCE
			beeDroneChance = CHANCE (type is always same as the class)
			items = { ITEM = CHANCE, ... }
			specialPre = function for special spawns, called before standard spawns
			specialPost = function for special spawns, called after standard spawns
			sting = true if this class is aggressive
		}

		Defaults used for omitted settings:
		CLASS = {
			active = "day",
			honeyType = CLASS,
			honeyChance = 0.6,
			beeDroneChance = 0.4,
			items = {}
			specialPre = nil,
			specialPost = nil,
			sting = false
		}
--]]
	-- Diurnal
		adaptive = { honeyType = "normal" },
		aggressive = {
			honeyType = "red", honeyChance = 0.8,
			items = { alienmeat = 0.1 },
			sting = true
		},
		arctic = {},
		arid = { items = { goldensand = 0.3 } },
		exceptional = {
			honeyType = "normal", honeyChance = 0.8,
			items = { fu_liquidhoney = 0.4 } ,
		},
		flower = { items = { beeflower = 0.25 } },
		forest = {},
		godly = {},
		hardy = { honeyType = "normal", honeyChance = 0.8 },
		hunter = { honeyType = "silk", honeyChance = 0.5 },
		jungle = { items = { plantfibre = 0.7 }	},
		metal = {
			honeyType = "red", honeyChance = 0.8,
			beeDroneChance = 1 / 3,
			items = { tungstenore = 1 / 3 },	-- FIXME: tungsten ore production worked in large and scented apiaries for miners with tungsten frame
			sting = true
		},
		miner = { specialPre = spawnMinerSpecialsEarly, specialPost = spawnMinerSpecialsLate },
		morbid = {
			items = { ghostlywax = 0.6 },
			sting = true
		},
		mythical = {},
		normal = {},
		plutonium = {},
		radioactive = {},
		red = {	items = { redwaxchunk = 0.2 } },
		solarium = {},
		sun = {},
		volcanic = {},
	-- Nocturnal
		moon = { active = "night" },
		nocturnal = { active = "night" },
	}

	local type, config
	local notnow = daytime and 'night' or 'day'

	local queen, drone = getEquippedBees()

	if queen == drone and beeSpawnList[queen] then
		local config = beeSpawnList[queen]
		local when = config.active or 'day'
--		sb.logInfo ('Checking ' .. queen .. ' (' .. when .. ' / ' .. notnow .. ')')

		if when ~= notnow then -- strictly, when == 'always' or == now
			beeActiveWhen = when

			if config.specialPre then config.specialPre(false) end

			local honeyType      = config.honeyType      or queen
			local honeyChance    = config.honeyChance    or 0.6
			local beeDroneChance = config.beeDroneChance or 0.4

			trySpawnHoney(honeyChance,    honeyType)
			trySpawnBee  (beeDroneChance, queen)
			trySpawnDrone(beeDroneChance, queen)

			if config.items and self.doItems then
				for item, chance in pairs(config.items) do
					trySpawnItems(chance, item)
				end
			end

			if config.specialPost then config.specialPost(true) end

			expelQueens(queen)  -- bitches this be MY house. (Kicks all queens but 1 out of the apiary)
		end

		-- found a match, so just return now indicating success
		return true
	end

	return false -- we have not found a match; returning false so we can run breedingBees() in main()
end


function breedingBees()
	beeComboList = {["normalforest"] = "hardy",
					["arcticvolcanic"] = "adaptive",
					["hardyadaptive"] = "exceptional",
					["aridadaptive"] = "miner",
					["jungleadaptive"] = "hunter",
					["hunterred"] = "aggressive",
					["aggressivenocturnal"] = "morbid",
					["radioactivehardy"] = "plutonium",
					["plutoniumexceptional"] = "solarium",
					["forestjungle"] = "flower",
					["flowernormal"] = "red",
					["flowerhardy"] = "red",
					["flowerexceptional"] = "mythical",
					["minernocturnal"] = "moon",
					["moonsolarium"] = "sun",
					["sunmythical"] = "godly",
					["metalsun"] = "mythical"
	}

	if daytime then
		local bee1Type = contents[self.queenSlot] and stripQueenDrone(contents[self.queenSlot].name)
		local bee2Type = contents[self.droneSlot] and stripQueenDrone(contents[self.droneSlot].name)
		local species = (bee1Type and bee2Type) and (beeComboList[bee1Type .. bee2Type] or beeComboList[bee2Type .. bee1Type])

		if species ~= nil then
--			sb.logInfo ('Checking ' .. bee1Type .. ' + ' .. bee2Type)
--			animator.setAnimationState("bees", "on")
			trySpawnHoney(0.2, "normal")
			trySpawnMutantBee(  0.25, species)
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
