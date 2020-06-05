function init()
	script.setUpdateDelta(5)
	bonusHandler=effect.addStatModifierGroup({})
end

function update(dt)
	--sb.logInfo("foodregen")
	if self.foodvalue == nil then 
		foodvalue=1 
	end
	if world.entityType(entity.id()) == "npc" then
		self.foodvalue = 35
	else
		self.foodvalue = status.resource("food")
	end

	if self.foodvalue > 50 then
		self.healingRate = 1.0005 / config.getParameter("healTime", 140)
	elseif self.foodvalue > 60 then
		self.healingRate = 1.0009 / config.getParameter("healTime", 140)
	elseif self.foodvalue > 70 then
		self.healingRate = 1.001 / config.getParameter("healTime", 140)
	else
		self.healingRate=0.0
	end
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*self.healingRate}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end