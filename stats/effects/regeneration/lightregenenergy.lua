require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"

function init()
	self.healingRate = 1.01
	self.healingTime=config.getParameter("healTime", 320)
	script.setUpdateDelta(5)
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