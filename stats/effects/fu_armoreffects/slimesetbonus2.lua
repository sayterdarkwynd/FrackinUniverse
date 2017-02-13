require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_slimeset2", {
	    {stat = "protoImmunity", amount = 1},
	    {stat = "insanityImmunity", amount = 1},
	    {stat = "biooozeImmunity", amount = 1},
	    {stat = "slimestickImmunity", amount = 1},
	    {stat = "slimefrictionImmunity", amount = 1},
	    {stat = "slimeImmunity", amount = 1},
	    {stat = "poisonStatusImmunity", baseMultiplier = 1},
	    {stat = "wetImmunity", amount = 1},
	    {stat = "shadowImmunity", amount = 1},
	    {stat = "poisonResistance", baseMultiplier = 0.35}
	})
end
