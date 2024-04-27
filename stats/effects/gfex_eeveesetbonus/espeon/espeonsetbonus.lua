function init()
	bonusHandler=effect.addStatModifierGroup({{stat = "physicalResistance", amount = 0.15},{stat = "fallDamageMultiplier", effectiveMultiplier = 0.7}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
