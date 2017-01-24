require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_cultistset", {
		{stat = "insanityImmunity" , amount = 1},
		{stat = "shadowImmunity" , amount = 1}
		{stat = "energyregenfu_armor75", amount = 1},
		{stat = "shadowResistance", amount = 0.65},
	})
end
