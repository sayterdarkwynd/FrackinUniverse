require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	    setBonusInit("fu_boneset", {
	      {stat = "powerMultiplier", baseMultiplier = 1.1},
	      {stat = "fireResistance", baseMultiplier = 1.2},
              {stat = "fallDamageMultiplier", baseMultiplier = 0.25}
	    })        
end