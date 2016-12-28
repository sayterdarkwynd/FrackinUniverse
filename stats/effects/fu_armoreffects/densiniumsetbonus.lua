require "/stats/effects/jumpboost/jumpboost25.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_densiniumset", {
		{stat = "ffextremeheatImmunity", amount = 1},
		{stat = "biomeheatImmunity", amount = 1},
		{stat = "protoImmunity", amount = 1},
		{stat = "extremepressureProtection", amount = 1},
		{stat = "ffextremecoldImmunity", amount = 1},
		{stat = "biomecoldImmunity", amount = 1},
		{stat = "sulphuricImmunity", amount = 1},
		{stat = "breathProtection", amount = 1},
		{stat = "physicalResistance", baseMultiplier = 0.15},
		{stat = "radiationburnImmunity", amount = 1}
	},
	callbacks )
end
