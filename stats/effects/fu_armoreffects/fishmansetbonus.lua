require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_fishmanset", {
	    {stat = "poisonStatusImmunity", amount = 1},
	    {stat = "protoImmunity", amount = 1},
	    {stat = "maxBreath", amount = 1400.0 },
	    {stat = "breathDepletionRate", amount = 1.0 },
	    {stat = "wetImmunity", amount = 1 },
		{stat = "poisonResistance", baseMultiplier = 0.55}
	})
end