function init()
	bonusHandler=effect.addStatModifierGroup({{stat = "tarStatusImmunity", amount = 1},{stat = "electricResistance", amount = 0.15}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
