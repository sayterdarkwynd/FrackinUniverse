function init()
	script.setUpdateDelta(5)
	self.healingRate = 1.0 / config.getParameter("healTime", 60)
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	if (world.entityType(entity.id())=="player") or status.resource("health")>=1 then
		effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.resourceMax("health")*self.healingRate*math.max(0,1+status.stat("healingBonus"))}})
	else
		effect.setStatModifierGroup(bonusHandler,{})
	end
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
