function init()
	bonusHandler=effect.addStatModifierGroup({{stat = "poisonResistance", amount = 0.15}, {stat = "biomeheatImmunity", amount = 1}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
