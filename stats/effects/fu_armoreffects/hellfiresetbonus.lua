require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    if (world.type() == "infernus") or (world.type() == "infernusdark") or (world.type() == "volcanic") or (world.type() == "magma")  then
	    setBonusInit("fu_hellfireset", {
		{stat = "physicalResistance", amount = 0.15},
		{stat = "maxHealth", baseMultiplier = 1.15},	
		{stat = "maxEnergy", baseMultiplier = 1.15},	    
		{stat = "sulphuricacidImmunity", amount = 1},
		{stat = "sulphuricImmunity", amount = 1},	
		{stat = "protoImmunity", amount = 1},
		{stat = "fireStatusImmunity", amount = 1},
		{stat = "lavaImmunity", amount = 1},
		{stat = "ffextremeheatImmunity", amount = 1},
		{stat = "wetImmunity", amount = 1},
		{stat = "biomeheatImmunity", amount = 1}
	    }) 
       else
	    setBonusInit("fu_hellfireset", {
		{stat = "sulphuricacidImmunity", amount = 1},
		{stat = "sulphuricImmunity", amount = 1},	
		{stat = "protoImmunity", amount = 1},
		{stat = "fireStatusImmunity", amount = 1},
		{stat = "lavaImmunity", amount = 1},
		{stat = "ffextremeheatImmunity", amount = 1},
		{stat = "wetImmunity", amount = 1},
		{stat = "biomeheatImmunity", amount = 1}
	    })        
    end  
	
end





