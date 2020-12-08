function init()
	script.setUpdateDelta(5)
	self.statHandler=effect.addStatModifierGroup({})
end

function update(dt)
	applyEffects()
end

function applyEffects()
	effect.setStatModifierGroup(self.statHandler,{{stat = "foodDelta", baseMultiplier = -1-(status.stat("xiBulbFoodBonus")+status.stat("xiBonus"))} })
end

function uninit()
	effect.removeStatModifierGroup(self.statHandler)
end
