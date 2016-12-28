require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    if (world.type() == "garden") or (world.type() == "forest") or (world.type() == "desert")  then
	    setBonusInit("fu_boneset", {
	      {stat = "maxHealth", baseMultiplier = 1.05},
	      {stat = "powerMultiplier", baseMultiplier = 1.05},
	      {stat = "physicalResistance", baseMultiplier = 1.05},
              {stat = "fallDamageMultiplier", baseMultiplier = 0.5}
	    }) 
       else
	    setBonusInit("fu_boneset", {
	      {stat = "maxHealth", baseMultiplier = 1.0},
	      {stat = "powerMultiplier", baseMultiplier = 1.0},
	      {stat = "physicalResistance", baseMultiplier = 1.0},
              {stat = "fallDamageMultiplier", baseMultiplier = 0.5}
	    })        
    end  	
end