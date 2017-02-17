require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	    setBonusInit("fu_boneset", {
	      {stat = "powerMultiplier", baseMultiplier = 1.1},
	      {stat = "fireResistance", baseMultiplier = 1.2},
              {stat = "grit", baseMultiplier = 1.25}
	    })        
end