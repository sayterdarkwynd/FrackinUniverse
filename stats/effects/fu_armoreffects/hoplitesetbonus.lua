require "/stats/effects/regeneration/regenerationminorarmorsethoplite.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    if (world.type() == "desert") or (world.type() == "thickjungle") or (world.type() == "mountainous") or (world.type() == "mountainous2") or (world.type() == "mountainous3") or (world.type() == "mountainous4")  then
		    setBonusInit("fu_hopliteset", {
		      {stat = "protoImmunity", amount = 1},
		      {stat = "insanityImmunity", amount = 1},
		      {stat = "critChance", amount = 6},
		      {stat = "physicalResistance", amount = 0.15},
		      {stat = "shieldRegen", amount = 0.5}
		    },callbacks) 
   else
		    setBonusInit("fu_hopliteset", {
		      {stat = "protoImmunity", amount = 1},
		      {stat = "insanityImmunity", amount = 1},
		      {stat = "critChance", amount = 3},
		      {stat = "shieldRegen", amount = 0.3}
		    },callbacks) 
    end  
end

