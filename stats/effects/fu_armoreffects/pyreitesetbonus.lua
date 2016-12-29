require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_pyreiteset", {
            {stat = "ffextremecoldImmunity", amount = 1},
            {stat = "biomecoldImmunity", amount = 1},
	    {stat = "fireStatusImmunity", amount = 1},
	    {stat = "shadowImmunity", amount = 1},      
	    {stat = "fireResistance", baseMultiplier = 0.75},
	    {stat = "shadowResistance", baseMultiplier = 0.15},
	    {stat = "iceResistance", baseMultiplier = 0.50}
	})
end








