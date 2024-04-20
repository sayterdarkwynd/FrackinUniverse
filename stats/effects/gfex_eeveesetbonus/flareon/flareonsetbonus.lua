function init()
	bonusHandler=effect.addStatModifierGroup({{stat = "iceResistance", amount = 0.15}, {stat = "biomecoldImmunity", amount = 1}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
