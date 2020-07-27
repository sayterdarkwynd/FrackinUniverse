require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  local bounds = mcontroller.boundBox()
  self.healingRate = 1.01
  self.healingTime=config.getParameter("healTime", 320)
  script.setUpdateDelta(5)
end

function getLight()
  local position = mcontroller.position()
  position[1] = math.floor(position[1])
  position[2] = math.floor(position[2])
  local lightLevel = math.min(world.lightLevel(position),1.0)
  lightLevel = math.floor(lightLevel * 100)
  return lightLevel
end


function daytimeCheck()
	daytime = world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	underground = world.underground(mcontroller.position())
end

function update(dt)
  daytimeCheck()
  undergroundCheck()
  local lightLevel = getLight()

	if daytime then
		if underground and lightLevel > 40 then
			self.healingRate = 1.003 / self.healTime
		elseif underground and lightLevel < 40 then
			self.healingRate = 0.0
		else
		    if lightLevel > 25 then
				self.healingRate=((((lightLevel-25.0)/75.0)+1.0)/self.healTime)
			else
				self.healingRate=0.0
			end
		end
	else
		self.healingRate=0.0
	end
	status.modifyResourcePercentage("energy", self.healingRate * dt)
end

function uninit()

end







