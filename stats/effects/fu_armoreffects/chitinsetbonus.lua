require "/stats/effects/damagebonus/damagebonus.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_chitinset", {
	    {stat = "sulphuricImmunity", amount = 1}
	},
	callbacks)
end