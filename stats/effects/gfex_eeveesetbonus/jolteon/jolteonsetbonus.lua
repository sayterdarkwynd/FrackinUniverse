function init()
	bonusHandler=effect.addStatModifierGroup({{stat = "electricResistance", amount = 0.15}, {stat = "electricStatusImmunity", amount = 1}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
