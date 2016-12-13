require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_slimeset", {
	    {stat = "protoImmunity", amount = 1},
	    {stat = "poisonResistance", baseMultiplier = 0.35}
	})
end
