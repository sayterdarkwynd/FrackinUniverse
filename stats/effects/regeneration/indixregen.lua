function init()
	--self.healingRate = 1.01 / config.getParameter("healTime", 180)
	self.healingRate = 1.0 / config.getParameter("healTime", 180)
	script.setUpdateDelta(10)
	bonusHandler=effect.addStatModifierGroup({})
end


function update(dt)
	--sb.logInfo("indixregen")
    if status.resourcePercentage("energy") >= 0.5 then
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=(status.resourceMax("health")*self.healingRate)*math.max(0,1+status.stat("healingBonus"))}})
		--status.modifyResourcePercentage("health", self.healingRate * dt)
	else
		effect.setStatModifierGroup(bonusHandler,{})
    end
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
