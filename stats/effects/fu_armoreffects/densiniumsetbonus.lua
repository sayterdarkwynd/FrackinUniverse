require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_densiniumset", {
		{stat = "ffextremeheatImmunity", amount = 1},
		{stat = "biomeheatImmunity", amount = 1},
		{stat = "sulphuricImmunity", amount = 1},
		{stat = "protoImmunity", amount = 1},
		{stat = "fireStatusImmunity", amount = 1},
		{stat = "extremepressureProtection", amount = 1},
		{stat = "ffextremecoldImmunity", amount = 1},
		{stat = "biomecoldImmunity", amount = 1},
		{stat = "sulphuricImmunity", amount = 1},
		{stat = "liquidnitrogenImmunity", amount = 1},
		{stat = "nitrogenfreezeImmunity", amount = 1},
		{stat = "ffextremeradiationImmunity", amount = 1},
		{stat = "biomeradiationImmunity", amount = 1},
		{stat = "sulphuricImmunity", amount = 1}
	})
end
