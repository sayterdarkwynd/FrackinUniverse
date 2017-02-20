require "/stats/effects/jumpboost/jumpboostwarriorrobes.lua"

callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
		    setBonusInit("fu_warriorrobesset", {
		      {stat = "shadowImmunity", amount = 1},
		      {stat = "insanityImmunity", amount = 1},
		      {stat = "critChance", amount = 8},
		      {stat = "foodDelta", baseMultiplier = 0.8}
		    },callbacks) 

end

