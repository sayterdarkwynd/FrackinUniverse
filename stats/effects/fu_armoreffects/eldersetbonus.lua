require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_elderset", {
	    {stat = "ffextremeradiationImmunity", amount = 1},
	    {stat = "biomeradiationImmunity", amount = 1},
	    {stat = "ffextremeheatImmunity", amount = 1},
	    {stat = "biomeheatImmunity", amount = 1},
	    {stat = "ffextremecoldImmunity", amount = 1},
	    {stat = "biomecoldImmunity", amount = 1},
	    {stat = "biooozeImmunity", amount = 1},
	    {stat = "sulphuricImmunity", amount = 1},
	    {stat = "liquidnitrogenImmunity", amount = 1},
	    {stat = "nitrogenfreezeImmunity", amount = 1},
	    {stat = "poisonStatusImmunity", amount = 1},
	    {stat = "protoImmunity", amount = 1},
	    {stat = "wetImmunity", amount = 1},
	    {stat = "grit", amount = 0.42},
	    {stat = "maxBreath", amount = 1400.0 },
	    {stat = "breathDepletionRate", amount = 1.0 },
	    {stat = "electricResistance", baseMultiplier = 0.35},
	    {stat = "poisonResistance", baseMultiplier = 0.65},
            {stat = "shadowResistance", amount = 0.7},
            {stat = "shadowImmunity", amount = 1}
	})
end