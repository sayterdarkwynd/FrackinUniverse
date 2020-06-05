require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.healingRate = 1.01 / config.getParameter("healTime", 320)
	script.setUpdateDelta(5)
	bonusHandler=effect.addStatModifierGroup({})
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
	--sb.logInfo("lightregen")
	daytime = daytimeCheck()
	underground = undergroundCheck()
	local lightLevel = getLight()

	if daytime then
		if underground and lightLevel < 40 then
			self.healingRate = 1.0009 / config.getParameter("healTime", 260)  
		elseif underground and lightLevel > 40 then
			self.healingRate = 1.001 / config.getParameter("healTime", 260)
		elseif lightLevel > 95 then
			self.healingRate = 1.01 / config.getParameter("healTime", 140)
		elseif lightLevel > 90 then
			self.healingRate = 1.008 / config.getParameter("healTime", 180)
		elseif lightLevel > 80 then
			self.healingRate = 1.007 / config.getParameter("healTime", 220)
		elseif lightLevel > 70 then
			self.healingRate = 1.006 / config.getParameter("healTime", 220)
		elseif lightLevel > 65 then
			self.healingRate = 1.005 / config.getParameter("healTime", 220)
		elseif lightLevel > 55 then
			self.healingRate = 1.004 / config.getParameter("healTime", 240)
		elseif lightLevel > 45 then
			self.healingRate = 1.003 / config.getParameter("healTime", 260)
		elseif lightLevel > 35 then
			self.healingRate = 1.002 / config.getParameter("healTime", 280)
		elseif lightLevel > 25 then
			self.healingRate = 1.001 / config.getParameter("healTime", 320)
		else
			self.healingRate=0.0
		end
	else
		self.healingRate=0.0
	end
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end