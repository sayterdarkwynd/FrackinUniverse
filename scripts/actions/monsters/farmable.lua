require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/util.lua"

-- param entity
function evolveFluffalo()
	local evolveTime = config.getParameter("evolveTime")
	if storage.spawnTime + evolveTime - (storage.evolveOffset or 0) < world.time() then
		local evolveType = config.getParameter("evolveType")
		local spawnPosition = vec2.add(mcontroller.position(), vec2.mul(config.getParameter("spawnOffset"), {mcontroller.facingDirection(), 1}))
		if not world.polyCollision(poly.translate(config.getParameter("spawnPoly"), spawnPosition)) then
			world.spawnMonster(evolveType, spawnPosition, {level = 1, aggressive = false})

			monster.setDropPool(nil)
			monster.setDeathParticleBurst(nil)
			monster.setDeathSound(nil)
			status.setResource("health", 0)
			return true
		end
	end
	return false
end

function resetMonsterHarvest()
	storage.produceRequired = util.randomInRange(config.getParameter("harvestTime"))
	storage.producePercent = 0
end

function hasMonsterHarvest(args, board)
	if not storage.producePercent then
		resetMonsterHarvest()
	end
	storage.producePercent = storage.producePercent + 0.333333333 * ((storage.happiness or 50)/100) * math.max(math.min(((storage.food or 100)-10)/10,1),0)
	return isMonsterHarvestable(args, board)
end

function isMonsterHarvestable(args, board)
	if (not storage.producePercent) or (not storage.produceRequired) then
		resetMonsterHarvest()
	end
 --storage.producePercent = storage.producePercent + 0.333333333 * ((storage.happiness or 50)/100) * math.max(math.min(((storage.food or 100)-10)/10,1),0)
	if (storage.producePercent and storage.produceRequired) and storage.producePercent >= storage.produceRequired then
		return true
	else
	if not storage.producePercent or not storage.produceRequired then
	 --sb.logError("/scripts/actions/monsters/farmable.lua: monster=<%s>, storage.producePercent=<%s>, storage.produceRequired=<%s>, configured harvest time: <%s>",world.monsterType(entity.id()),storage.producePercent,storage.produceRequired,config.getParameter("harvestTime"))
	 --happens primarily with baby mooshi
	end
		return false
	end
end

function dropMonsterHarvest(args, board)
	local treasurePool = config.getParameter("harvestPool")
	local treasure = root.createTreasure(treasurePool, monster.level())
	local spawnPosition = vec2.add(mcontroller.position(), config.getParameter("harvestSpawnOffset", {0, 0}))

	for _,item in pairs(treasure) do
		world.spawnItem(item, spawnPosition)
	end
	resetMonsterHarvest()
	return true
end

function findTrough(args)
	local troughtypelist = root.assetJson('/scripts/actions/monsters/farmable.config').troughlist
	local troughdislist = {}
	for i = 1,#troughtypelist do
		local objectList = world.objectQuery(args.position,100,{name = troughtypelist[i], order = "nearest"})
		if #objectList > 0 then
			local entityKey = objectList[1]
			troughdislist[entityKey] = world.magnitude(args.position,world.entityPosition(entityKey))
		end
	end
	if not next(troughdislist) then return false end

	-- Ignore all troughs except the closest one.
	for entityKey1,distance1 in pairs(troughdislist) do
		for entityKey2,distance2 in pairs(troughdislist) do
			if entityKey1 ~= entityKey2 then
				if distance1 > distance2 then
					troughdislist[entityKey1] = nil
				else
					troughdislist[entityKey2] = nil
				end
			end
		end
	end

	local closestEntityKey = next(troughdislist)
	return true,{entity = closestEntityKey}
end

function eatFood(args)
	if (not args.entity) or (not world.entityExists(args.entity)) or (not world.containerSize(args.entity)) then return false end
	local foodlist = root.assetJson('/scripts/actions/monsters/farmable.config').foodlists
	local diet = config.getParameter('diet','omnivore')

	local eaten = false
	for pos,item in pairs(world.containerItems(args.entity)) do
		local itemConfig = root.itemConfig(item).config
		local cat=string.lower(itemConfig.category or "")
		local foodValue=(itemConfig.foodValue and (itemConfig.foodValue>0) and itemConfig.foodValue) or (((cat == "food") or (cat == "farmbeastfood") or (cat == "preparedfood")) and 10) or 1
		--if itemConfig.category == "food" and not foodValue then foodValue = 10 end

		if diet == 'omnivore' then
			for _,value in pairs(foodlist.herbivore) do
				if item.name == value then
					local consume = math.min(math.ceil((80-storage.food)/foodValue),item.count)
					if world.containerConsumeAt(args.entity,pos-1,consume) then
						storage.food = storage.food + consume * foodValue
						storage.evolveOffset = (storage.evolveOffset or 0) + consume * foodValue
						eaten = true
						break
					end
				end
			end
			for _,value in pairs(foodlist.carnivore) do
				if item.name == value then
					local consume = math.min(math.ceil((80-storage.food)/foodValue),item.count)
					if world.containerConsumeAt(args.entity,pos-1,consume) then
						storage.food = storage.food + consume * foodValue
						storage.evolveOffset = (storage.evolveOffset or 0) + consume * foodValue
						eaten = true
						break
					end
				end
			end
		elseif diet == 'specialomnivore' then
			for _,value in pairs(foodlist.herbivore) do
				if item.name == value then
					local consume = math.min(math.ceil((80-storage.food)/foodValue),item.count)
					if world.containerConsumeAt(args.entity,pos-1,consume) then
						storage.food = storage.food + consume * foodValue
						storage.evolveOffset = (storage.evolveOffset or 0) + consume * foodValue
						eaten = true
						break
					end
				end
			end
			for _,value in pairs(foodlist.specialomnivore) do
				if item.name == value then
					local consume = math.min(math.ceil((80-storage.food)/foodValue),item.count)
					if world.containerConsumeAt(args.entity,pos-1,consume) then
						storage.food = storage.food + consume * foodValue
						storage.evolveOffset = (storage.evolveOffset or 0) + consume * foodValue
						eaten = true
						break
					end
				end
			end
		else
			for _,value in pairs(foodlist[diet]) do
				if (item.name == value) then
					local consume = math.min(math.ceil((80-storage.food)/foodValue),item.count)
					if world.containerConsumeAt(args.entity,pos-1,consume) then
						storage.food = storage.food + consume * foodValue
						storage.evolveOffset = (storage.evolveOffset or 0) + consume * foodValue
						eaten = true
						break
					end
				end
			end
		end

		displayHappiness()
		if storage.food >= 100 then
			break
		end
	end

	self.timer2 = (self.timer2 or 180) - 1
	displayFoodType()

	return eaten
end

function getFood()
	self.timer = (self.timer or 90) - 1
	self.canMate = 1 --prevent mating till they have eaten at least once
	happinessCalculation()
	displayHappiness()
	checkMate()
	return true,{food=storage.food}
end

function removeFood(args)
	storage.food = math.max((storage.food or 100) - 0.277777778/config.getParameter('hungerTime',20),0)
	storage.mateTimer = math.max((storage.mateTimer or 120) - 5/config.getParameter('mateTimer',120),0)
	self.timerPoop = (self.timerPoop or 90) - 1

	if self.timerPoop <= 0 and storage.food >= 50 then
		checkPoop()
		self.timerPoop = 90
	end
	return true
end


function happinessCalculation()
	storage.happiness = storage.happiness or 50
	if storage.food < 20 then
		storage.happiness = math.max(storage.happiness - 0.00462962963,0)
	else
		storage.happiness = math.min(storage.happiness + 0.00462962963,100)
	end
	return true
end

function displayFoodType()
	if self.timer2 <= 0 then
		local diet = config.getParameter('diet','omnivore')
		local configBombDrop = { speed = 10 }
		if diet == 'carnivore' then
			world.spawnProjectile("fu_carnivore", mcontroller.position(), entity.id(), {0, 30}, false, configBombDrop)
		elseif diet == 'omnivore' or diet == 'specialomnivore' then
			world.spawnProjectile("fu_omnivore", mcontroller.position(), entity.id(), {0, 30}, false, configBombDrop)
		elseif diet == 'herbivore' then
			world.spawnProjectile("fu_herbivore", mcontroller.position(), entity.id(), {0, 30}, false, configBombDrop)
		elseif diet == 'lunar' then
			world.spawnProjectile("fu_lunar", mcontroller.position(), entity.id(), {0, 30}, false, configBombDrop)
		elseif diet == 'robo' then
			world.spawnProjectile("fu_robo", mcontroller.position(), entity.id(), {0, 30}, false, configBombDrop)
		end
		self.timer2 = 180
	end
end

function displayHappiness()
	if self.timer <= 0 then
		local configBombDrop = { speed = 10}
	 --monster.say(storage.food)
		if storage.food <= 0 then
			world.spawnProjectile("fu_sad", mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop)
		elseif storage.food >= 90 then
			world.spawnProjectile("fu_happy2", mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop)
		elseif storage.food >= 50 then
			world.spawnProjectile("fu_happy", mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop)
		elseif storage.food >=30 then
			world.spawnProjectile("fu_hungry",mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop)
		end
		self.timer = 90
	end
end

-- Fed livestock breed more often. Breeding removes most of their current food. They must be ready to mate, 70% happy, and beat the difficulty class of the roll
function checkMate()
	self.d20 = math.random(20) + (storage.happiness/10) --roll a d20. Happiness increases value of roll, increasing likelihood of success by up to 50%
	self.eggType = config.getParameter("eggType")
	--is egg, and the d20 roll exceeds or equals the difficulty (19)
	if (self.eggType) and (self.d20 >= 19) then 
		--creature is full enough, the wait timer is up, and the creature is currently capable of mating (has eaten at least once)
		if (storage.mateTimer <= 0) and (self.canMate) and (storage.food >= 45) then 
			storage.mateTimer = 120 - (storage.food/5)
			world.spawnItem( self.eggType, mcontroller.position(), 1 )
			world.spawnProjectile("fu_egglay",mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop)
			animator.playSound("harvest")
			storage.food = storage.food - 45
		end
	end
end

function checkPoop() -- poop to fertilize trays , pee to water soil, etc
	self.foodMod = storage.food/20 * config.getParameter('hungerTime',20)
	storage.canPoop = config.getParameter('canPoop',1)
	if storage.canPoop == 2 then -- is robot
		self.randPoop = math.random(1120) - self.foodMod
		if self.randPoop <= 1 then
			animator.playSound("deathPuff")
			world.spawnItem("ff_spareparts", mcontroller.position(), 1)
		elseif self.randPoop >=950 then
			animator.playSound("deathPuff")
			world.spawnLiquid(mcontroller.position(), 5, 1) --oil urination (5)
		end
	elseif storage.canPoop == 3 then -- is lunar
		self.randPoop = math.random(1120) - self.foodMod
		if self.randPoop <= 1 then
			animator.playSound("deathPuff")
			world.spawnItem("supermatter", mcontroller.position(), 1)
		elseif self.randPoop >=950 then
			animator.playSound("deathPuff")
			world.spawnLiquid(mcontroller.position(), 11, 1) --liquidfuel urination (11)
		end
	else
		self.randPoop = math.random(920) - self.foodMod
		if self.randPoop <= 1 then
			animator.playSound("deathPuff")
			world.spawnItem("poop", mcontroller.position(), 1)
		elseif self.randPoop >= 850 then
			animator.playSound("deathPuff")
			world.spawnLiquid(mcontroller.position(), 1, 1) --liquidwater urination (1)
		end
	end
end



function checkSoil()
	local tileModConfig = root.assetJson('/scripts/actions/monsters/farmable.config').tileMods
	configBombDrop = { speed = 20}
	if world.mod(mcontroller.position(), "foreground") then
	 --setAnimationState("body", "graze")
		for _,value in pairs(tileModConfig.mainTiles) do
			if world.mod(mcontroller.position(), "foreground") == value then
				world.spawnProjectile("grazingprojectilespray",mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop)
			end
		end
		storage.food = storage.food + 10
	end
end
