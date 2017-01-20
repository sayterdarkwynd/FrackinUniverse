require "/stats/effects/fu_tileeffects/gravmaker/gravmakerspacefarer.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    if (world.type() == "asteroids") or (world.type() == "barrenasteroids") or (world.type() == "iceasteroids") or (world.type() == "elderasteroid") or (world.type() == "corruptasteroid") then
    
        setBonusInit("fu_spacefarerset", {
	    {stat = "fireStatusImmunity", amount = 1},
	    {stat = "maxBreath", baseMultiplier = 50.0 },
	    {stat = "slushslowImmunity", amount = 1},
	    {stat = "protoImmunity", amount = 1},
	    {stat = "liquidnitrogenImmunity", amount = 1},
	    {stat = "nitrogenfreezeImmunity", amount = 1},
	    {stat = "iceslipImmunity", amount = 1},
	    {stat = "extremepressureProtection", amount = 1},
	    {stat = "asteroidImmunity", amount = 1},
	    {stat = "physicalResistance", amount = 0.25}
	},
	callbacks)    
    
    
    else
        setBonusInit("fu_spacefarerset", {
	    {stat = "fireStatusImmunity", amount = 1},
	    {stat = "maxBreath", baseMultiplier = 50.0 },
	    {stat = "slushslowImmunity", amount = 1},
	    {stat = "protoImmunity", amount = 1},
	    {stat = "liquidnitrogenImmunity", amount = 1},
	    {stat = "nitrogenfreezeImmunity", amount = 1},
	    {stat = "iceslipImmunity", amount = 1},
	    {stat = "extremepressureProtection", amount = 1},
	    {stat = "asteroidImmunity", amount = 1},
	    {stat = "physicalResistance", amount = 0.25}
	})    
    
    end

end