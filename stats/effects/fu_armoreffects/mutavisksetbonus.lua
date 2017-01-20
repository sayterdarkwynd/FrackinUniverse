

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_mutaviskset", {
		{stat = "ffextremeradiationImmunity", amount = 1},
		{stat = "radiationburnImmunity", amount = 1},
		{stat = "biomeradiationImmunity", amount = 1},
		{stat = "fallDamageMultiplier", effectiveMultiplier = 0.5},
                {stat = "radioactiveResistance", baseMultiplier = 0.35}
	})
end
