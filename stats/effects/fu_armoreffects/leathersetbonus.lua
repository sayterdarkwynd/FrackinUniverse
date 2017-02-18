require "/stats/effects/runboost/runboostleatherarmor.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    if (world.type() == "garden") or (world.type() == "desert")  then
	    setBonusInit("fu_leatherset", {
	      {stat = "maxEnergy", baseMultiplier = 1.05},
	      {stat = "critChance", baseMultiplier = 1.05},
              {stat = "grit", baseMultiplier = 0.2}
	    },callbacks) 
       else
	    setBonusInit("fu_leatherset", {
	      {stat = "maxEnergy", baseMultiplier = 1.0},
	      {stat = "critChance", baseMultiplier = 1.05},
              {stat = "grit", baseMultiplier = 0.1}
	    },callbacks)        
    end  	
end