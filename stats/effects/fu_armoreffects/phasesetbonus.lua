require "/stats/effects/regeneration/regenerationminorarmorset3.lua"
require "/stats/effects/runboost/runboost25.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_phaseset", {
		{stat ="electricResistance", amount = 0.4},
		{stat ="electricStatusImmunity" , amount = 1 },
		{stat ="pressureProtection" , amount = 1 },
		{stat ="extremepressureProtection" , amount = 1 }
	},callbacks)
end
