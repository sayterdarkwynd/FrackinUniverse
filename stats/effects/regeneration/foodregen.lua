function init()
	script.setUpdateDelta(5)
	bonusHandler=effect.addStatModifierGroup({})
	self.healTime=config.getParameter("healTime", 140)
end

function update(dt)
	if not status.isResource("food") then
		self.foodvalue = 35
	else
		self.foodvalue = status.resource("food")
	end

	if self.foodvalue > 70 then
		self.healingRate = 1.001 / self.healTime
	elseif self.foodvalue > 60 then
		self.healingRate = 1.0009 / self.healTime
	elseif self.foodvalue > 50 then
		self.healingRate = 1.0005 / self.healTime
	else
		self.healingRate=0.0
	end
	effect.setStatModifierGroup(bonusHandler,{{stat="healthRegen",amount=status.resourceMax("health")*self.healingRate*math.max(0,1+status.stat("healingBonus"))}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end