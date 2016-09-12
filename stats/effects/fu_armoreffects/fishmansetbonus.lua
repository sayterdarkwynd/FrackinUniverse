require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_elderset", {
	    {stat = "poisonStatusImmunity", amount = 1},
	    {stat = "protoImmunity", amount = 1},
	    {stat = "maxBreath", amount = 1400.0 },
	    {stat = "breathDepletionRate", amount = 1.0 }
	})
end