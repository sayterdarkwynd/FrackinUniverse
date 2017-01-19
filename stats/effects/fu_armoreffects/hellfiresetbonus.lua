require "/stats/effects/liquidimmunity/lavahealing.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_hellfireset", {
		{stat = "sulphuricacidImmunity", amount = 1},
		{stat = "sulphuricImmunity", amount = 1},	
		{stat = "protoImmunity", amount = 1},
		{stat = "fireStatusImmunity", amount = 1},
		{stat = "lavaImmunity", amount = 1},
		{stat = "ffextremeheatImmunity", amount = 1},
		{stat = "wetImmunity", amount = 1},
		{stat = "biomeheatImmunity", amount = 1}
	},callbacks)
	
end


