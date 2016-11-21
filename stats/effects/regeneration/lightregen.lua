function init()
  local bounds = mcontroller.boundBox()
  self.healingRate = 1.01 / config.getParameter("healTime", 420)
  script.setUpdateDelta(10)
end

function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = world.lightLevel(position)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end

function daytimeCheck()
	daytime = world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	underground = world.underground(position) 
end

function update(dt)
  local lightLevel = getLight()
 if daytime or underground and lightLevel > 80 then
	 if lightLevel > 95 then
	   self.healingRate = 1.01 / config.getParameter("healTime", 140)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  elseif lightLevel > 90 then
	   self.healingRate = 1.008 / config.getParameter("healTime", 180)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  elseif lightLevel > 80 then
	   self.healingRate = 1.007 / config.getParameter("healTime", 220)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  elseif lightLevel > 70 then
	   self.healingRate = 1.006 / config.getParameter("healTime", 240)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  elseif lightLevel > 65 then
	   self.healingRate = 1.005 / config.getParameter("healTime", 270)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  elseif lightLevel > 55 then
	   self.healingRate = 1.004 / config.getParameter("healTime", 300)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  elseif lightLevel > 45 then
	   self.healingRate = 1.003 / config.getParameter("healTime", 340)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  elseif lightLevel > 35 then
	   self.healingRate = 1.002 / config.getParameter("healTime", 380)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  elseif lightLevel > 25 then
	   self.healingRate = 1.001 / config.getParameter("healTime", 420)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
	  end  
  end
end

function uninit()

end