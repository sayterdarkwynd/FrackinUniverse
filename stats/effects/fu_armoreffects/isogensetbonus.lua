require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_pyreiteset", {
            {stat = "ffextremeheatImmunity", amount = 1},
            {stat = "biomeheatImmunity", amount = 1},
	    {stat = "protoImmunity", amount = 1},
	    {stat = "sulphuricacidImmunity", amount = 1},            
	    {stat = "poisonResistance", baseMultiplier = 0.50},
	    {stat = "physicalResistance", baseMultiplier = 0.05},
	    {stat = "iceResistance", baseMultiplier = 0.75}
	})
end








