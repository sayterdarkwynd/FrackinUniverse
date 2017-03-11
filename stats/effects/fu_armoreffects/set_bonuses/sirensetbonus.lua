require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    if (world.type() == "ocean") or (world.type() == "tidewater") or (world.type() == "strangesea")  then
	    setBonusInit("fu_sirenset", {
	      {stat = "maxEnergy", baseMultiplier = 1.15},
	      {stat = "shieldStaminaRegen", baseMultiplier = 1.4},
	      {stat = "maxBreath", baseMultiplier = 5},
	      {stat = "poisonResistance", amount = 0.30}
	    }) 
       else
	    setBonusInit("fu_sirenset", {
	      {stat = "maxEnergy", baseMultiplier = 1.05},
	      {stat = "shieldStaminaRegen", baseMultiplier = 1.25},
	      {stat = "maxBreath", baseMultiplier = 2},
	      {stat = "poisonResistance", amount = 0.15}
	    })        
    end  	
end