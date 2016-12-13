require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_shadowboneset", {
			{stat = "insanityImmunity", amount = 1},
			{stat = "shadowImmunity", amount = 1},
	    {stat = "shadowResistance", baseMultiplier = 0.3}
	})
end
