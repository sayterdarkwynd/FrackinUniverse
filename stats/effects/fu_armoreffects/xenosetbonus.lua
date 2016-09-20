require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_xenoset", {
		{stat = "biooozeImmunity", amount = 1},
		{stat = "biomeheatImmunity", amount = 1},
		{stat = "biomecoldImmunity", amount = 1},
		{stat = "biomeradiationImmunity", amount = 1},
		{stat = "wetImmunity", amount = 1},
		{stat = "extremepressureProtection", amount = 1}
	})
end