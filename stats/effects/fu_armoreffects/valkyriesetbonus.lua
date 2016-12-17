

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_valkyrieset", {
		{stat = "breathProtection", amount = 1},
		{stat = "pressureProtection", amount = 1},
		{stat = "extremepressureProtection", amount = 1},
		{stat = "fallDamageMultiplier", effectiveMultiplier = 0.25},
		{stat = "electricResistance", effectiveMultiplier = 0.30}
	}

	)
end
