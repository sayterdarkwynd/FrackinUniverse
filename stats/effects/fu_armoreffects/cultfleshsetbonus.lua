require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_cultfleshset", {
	    {stat = "shadowImmunity", amount = 1},
	    {stat = "shadowResistance", baseMultiplier = 0.2}
	})
end
