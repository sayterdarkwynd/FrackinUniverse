require "/stats/effects/runboost/runboostmissionaryarmor.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    setBonusInit("fu_missionaryset", {
      {stat = "powerMultiplier", baseMultiplier = 1.25},
      {stat = "critBonus", baseMultiplier = 1.05},
      {stat = "grit", baseMultiplier = 0.05}
    },callbacks)        
end