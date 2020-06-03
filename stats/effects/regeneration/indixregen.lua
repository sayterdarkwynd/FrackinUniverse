require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	self.healingRate = 1.01 / config.getParameter("healTime", 180)
	script.setUpdateDelta(5)
	bonusHandler=effect.addStatModifierGroup({})
end


function update(dt)
	--sb.logInfo("indixregen")
    if status.resource("energy") >= status.stat("maxEnergy")/2 then
		self.healingRate = 1.0009 / config.getParameter("healTime", 180)
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})
		--status.modifyResourcePercentage("health", self.healingRate * dt)  
	else
		effect.setStatModifierGroup(bonusHandler,{})
    end

end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
