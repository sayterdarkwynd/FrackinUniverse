require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  local bounds = mcontroller.boundBox()
  self.healingRate = 1.01 / config.getParameter("healTime", 320)
  script.setUpdateDelta(5)
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
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position()) 
end

function update(dt)
  daytime = daytimeCheck()
  underground = undergroundCheck()
  local lightLevel = getLight()

  if daytime then
    if underground and lightLevel > 40 then
      	   self.healingRate = 1.003 / config.getParameter("healTime", 260)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 95 then
	   self.healingRate = 1.01 / config.getParameter("healTime", 140)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 90 then
	   self.healingRate = 1.008 / config.getParameter("healTime", 180)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 80 then
	   self.healingRate = 1.007 / config.getParameter("healTime", 220)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 70 then
	   self.healingRate = 1.006 / config.getParameter("healTime", 220)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 65 then
	   self.healingRate = 1.005 / config.getParameter("healTime", 220)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 55 then
	   self.healingRate = 1.004 / config.getParameter("healTime", 240)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 45 then
	   self.healingRate = 1.003 / config.getParameter("healTime", 260)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 35 then
	   self.healingRate = 1.002 / config.getParameter("healTime", 280)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    elseif lightLevel > 25 then
	   self.healingRate = 1.001 / config.getParameter("healTime", 320)
	   status.modifyResourcePercentage("health", self.healingRate * dt)
    end  
  end

end

function uninit()

end







