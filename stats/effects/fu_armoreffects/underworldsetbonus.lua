require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    setBonusInit("fu_underworldset", {
      {stat = "maxEnergy", baseMultiplier = 1.0},
      {stat = "electricResistance", baseMultiplier = 1.10},
      {stat = "physicalResistance", baseMultiplier = 1.10},
      {stat = "critBonus", baseMultiplier = 1.15}
    })        
end