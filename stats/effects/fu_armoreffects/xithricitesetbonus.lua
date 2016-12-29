require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_xithriciteset", {
            {stat = "ffextremeradiationImmunity", amount = 1},
            {stat = "biomeradiationImmunity", amount = 1},
	    {stat = "shadowImmunity", amount = 1}, 
	    {stat = "insanityImmunity", amount = 1}, 
	    {stat = "cosmicResistance", baseMultiplier = 0.75},
	    {stat = "shadowResistance", baseMultiplier = 0.15},
	    {stat = "radioactiveResistance", baseMultiplier = 0.50}
	})
end








