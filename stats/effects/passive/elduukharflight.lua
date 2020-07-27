function init() 
  self.species = world.entitySpecies(entity.id())
  if not self.species == "elduukhar" then
    effect.die()
  end
    self.healingRate = 1.01 / config.getParameter("healTime", 220)
    hungerLevel = status.resource("food")
    baseValue = config.getParameter("healthDown",0)*(status.resourceMax("food"))
    self.tickTime = 1.0
    self.tickTimePenalty = 5.0
    self.tickTimer = self.tickTime 
    self.tickTimerPenalty = self.tickTimePenalty
end

function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = math.min(world.lightLevel(position),1.0)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end


function update(dt)
    if status.isResource("food") then
	self.foodValue = status.resource("food")
	hungerLevel = status.resource("food")
    else
	self.foodValue = 50
	hungerLevel = 50
    end
    baseValue = config.getParameter("healthDown",0)*(status.resourceMax("food"))
    self.tickTimer = self.tickTimer - dt
    self.tickTimerPenalty = self.tickTimerPenalty - dt
    self.foodValue = status.resource("food")    
end


function uninit()
  
end