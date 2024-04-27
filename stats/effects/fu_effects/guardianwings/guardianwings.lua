function init()
	script.setUpdateDelta(5)
	self.healingRate=config.getParameter("regenRate",1/200)
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
