require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/util.lua"

-- param entity
function evolveFluffalo()
  local evolveTime = config.getParameter("evolveTime")
  if storage.spawnTime + evolveTime < world.time() then
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
  if storage.producePercent >= storage.produceRequired then
    return true
  else
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

function eatFood(args)
  if not args.entity then return false end
  local foodlist = root.assetJson('/scripts/actions/monsters/farmable.config').foodlists
  local diet = config.getParameter('diet','omnivore')
  local eaten = false
  for pos,item in pairs(world.containerItems(args.entity)) do
    local itemConfig = root.itemConfig(item).config
    if diet == 'omnivore' then
	  for _,value in pairs(foodlist.herbivore) do
	    if item.name == value then
	      local consume = math.min(math.ceil((80-storage.food)/itemConfig.foodValue),item.count)
		  if world.containerConsumeAt(args.entity,pos-1,consume) then
		    storage.food = storage.food + consume * itemConfig.foodValue
		    eaten = true
		    break
		  end
		end
	  end
	  for _,value in pairs(foodlist.carnivore) do
	    if item.name == value then
	      local consume = math.min(math.ceil((80-storage.food)/itemConfig.foodValue),item.count)
		  if world.containerConsumeAt(args.entity,pos-1,consume) then
		    storage.food = storage.food + consume * itemConfig.foodValue
		    eaten = true
		    break
		  end
		end
	  end
	else
	  for _,value in pairs(foodlist[diet]) do
	    if item.name == value then
	      local consume = math.min(math.ceil((80-storage.food)/itemConfig.foodValue),item.count)
		  if world.containerConsumeAt(args.entity,pos-1,consume) then
		    storage.food = storage.food + consume * itemConfig.foodValue
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
  return eaten
end

function getFood()
  self.timer = (self.timer or 90) - 1
  displayHappiness()	
  return true,{food=storage.food}
end

function removeFood(args)
  storage.food = math.max((storage.food or 100) - 0.277777778/config.getParameter('hungerTime',20),0)	
  return true
end

function displayHappiness()
  if self.timer <= 0 then
	local configBombDrop = { speed = 10}
	  if storage.food <= 0 then
	    world.spawnProjectile("fu_sad", mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop) 
	  elseif storage.food >= 80 then 
	    world.spawnProjectile("fu_happy", mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop) 
	    checkPoop()
	  elseif storage.food >=50 then
	    world.spawnProjectile("fu_hungry",mcontroller.position(), entity.id(), {0, 20}, false, configBombDrop) 
	    checkPoop()
	  end     
	self.timer = 90
	
  end
end

function checkPoop()
      -- does the animal need to poop?
        self.foodMod = storage.food/20 * config.getParameter('hungerTime',20)
  	self.randPoop = math.random(500) - self.foodMod
  	if self.randPoop < 1 then self.randPoop = 1 end
  	--sb.logInfo("poop roll = "..self.randPoop)
  	--sb.logInfo("mod = "..self.foodMod)
  	if self.randPoop <= 1.14 then
  	  animator.playSound("deathPuff")
  	  world.spawnItem("poop", mcontroller.position(), 1)
	end	
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