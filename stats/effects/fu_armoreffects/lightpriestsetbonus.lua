require "/stats/effects/regeneration/regenerationminorarmorset5.lua"
require "/stats/effects/runboost/runboost10.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_lightpriestset", {
	    {stat = "insanityImmunity", amount = 1},
	    {stat = "radiationburnImmunity", amount = 1}
	},callbacks)
end
