require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_isogenset", {
            {stat = "ffextremeheatImmunity", amount = 1},
            {stat = "biomeheatImmunity", amount = 1},
	    {stat = "protoImmunity", amount = 1},
	    {stat = "sulphuricacidImmunity", amount = 1},            
	    {stat = "poisonResistance", amount = 0.50},
	    {stat = "physicalResistance", amount = 0.05},
	    {stat = "iceResistance", amount = 0.75}
	})
end








