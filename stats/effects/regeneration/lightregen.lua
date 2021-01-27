require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.healingRate = 1.01 / config.getParameter("healTime", 320)
	script.setUpdateDelta(5)
	self.healTime=config.getParameter("healTime", 140)
	bonusHandler=effect.addStatModifierGroup({})
end

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	return math.floor(math.min(world.lightLevel(position),1.0) * 100)
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
end

function update(dt)
	--sb.logInfo("lightregen")
	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()

	if daytime then
		if underground and lightLevel < 40 then
			self.healingRate = 1.0009 / self.healTime
		elseif underground and lightLevel > 40 then
			self.healingRate = 1.001 / self.healTime
		else
		    if lightLevel > 25 then
				self.healingRate=((((lightLevel-25.0)/37.5)+1.0)/self.healTime)
			else
				self.healingRate=0.0
			end
		end
	else
		self.healingRate=0.0
	end
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.resourceMax("health")*self.healingRate*math.max(0,1+status.stat("healingBonus"))}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end