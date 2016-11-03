require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
  
    setBonusInit("fu_spacefarerset", {
	    {stat = "fireStatusImmunity", amount = 1},
	    {stat = "maxBreath", baseMultiplier = 50.0 },
	    {stat = "slushslowImmunity", amount = 1},
	    {stat = "protoImmunity", amount = 1},
	    {stat = "liquidnitrogenImmunity", amount = 1},
	    {stat = "nitrogenfreezeImmunity", amount = 1},
	    {stat = "iceslipImmunity", amount = 1},
	    {stat = "extremepressureProtection", amount = 1},
	    {stat = "asteroidImmunity", amount = 1}
	})
end