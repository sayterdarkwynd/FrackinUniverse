require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    if (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "desertwastesdark")  then
	    setBonusInit("fu_nomadset", {
	      {stat = "blacktarImmunity", baseMultiplier = 1},
	      {stat = "quicksandImmunity", baseMultiplier = 1},
	      {stat = "maxHealth", baseMultiplier = 1.15},
	      {stat = "maxEnergy", baseMultiplier = 1.10},
	      {stat = "powerMultiplier", baseMultiplier = 1.10},
	      {stat = "physicalResist", baseMultiplier = 1.10},
              {stat = "radiationburnImmunity", amount = 1},
              {stat = "sandstormImmunity", baseMultiplier = 1},
              {stat = "shieldStaminaRegen", baseMultiplier = 1.10}
	    })
    else
	    setBonusInit("fu_nomadset", {
	      {stat = "blacktarImmunity", baseMultiplier = 1},
	      {stat = "quicksandImmunity", baseMultiplier = 1},
	      {stat = "sandstormImmunity", baseMultiplier = 1},
              {stat = "radiationburnImmunity", amount = 1},
              {stat = "shieldStaminaRegen", baseMultiplier = 1.10}
	    })
    end
end
