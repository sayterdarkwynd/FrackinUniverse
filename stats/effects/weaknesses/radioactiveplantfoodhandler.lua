function init()
	script.setUpdateDelta(5)
	self.statHandler=effect.addStatModifierGroup({})
end

function update(dt)
	applyEffects()
end

function applyEffects()
	self.bonusValue = status.stat("xiBonus") * 2
	effect.setStatModifierGroup(self.statHandler,{{stat = "foodDelta", baseMultiplier = -1-(status.stat("xiBulbFoodBonus")+self.bonusValue)} })
end

function uninit()
	effect.removeStatModifierGroup(self.statHandler)
end