function init()
	bonusHandler=effect.addStatModifierGroup({{stat = "biomeradiationImmunity", amount = 1},{stat = "radioactiveResistance", amount = 0.15},{stat = "sulphuricImmunity", amount = 1}})
end

function uninit()
	effect.removeStatModifierGroup(bonusHandler)
end
