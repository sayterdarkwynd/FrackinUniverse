require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_phaseset", {
		{stat = "electricResistance", amount = 0.4},
		{stat ="electricStatusImmunity" , amount = 1 }
	})
end
