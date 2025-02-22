require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/stats/effects/fu_statusUtil.lua"

function init()
	script.setUpdateDelta(5)
	self.healTime=config.getParameter("healTime", 140)
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	local lightLevel = getLight()
	local healingRate = 0.0

	if lightLevel > 25 then
		healingRate = ((((lightLevel-25.0)/37.5)+1.0)/self.healTime)
	end

	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.resourceMax("health")*healingRate*math.max(0,1+status.stat("healingBonus"))}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
