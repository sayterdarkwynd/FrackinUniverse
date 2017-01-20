require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    if (world.type() == "arboreal") or (world.type() == "arboreal2") or (world.type() == "arborealdark")  then
      setBonusInit("fu_reptileset", {
        {stat = "maxHealth", baseMultiplier = 1.1},
        {stat = "powerMultiplier", baseMultiplier = 1.1},
        {stat = "physicalResistance", baseMultiplier = 1.1},
        {stat = "sulphuricImmunity", amount = 1},
        {stat = "protoImmunity", amount = 1}
      })
    else
      setBonusInit("fu_reptileset", {
        {stat = "maxHealth", baseMultiplier = 1.0},
        {stat = "powerMultiplier", baseMultiplier = 1.0},
        {stat = "physicalResistance", baseMultiplier = 1.0},
        {stat = "sulphuricImmunity", amount = 1},
        {stat = "protoImmunity", amount = 1}
      })
    end
end
