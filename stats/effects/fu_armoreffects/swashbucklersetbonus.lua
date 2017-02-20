require "/stats/effects/jumpboost/jumpboostswashbuckler.lua"
callbacks = { { init = init, update = update, uninit = uninit } }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
  setBonusInit("fu_swashbucklerset", {
    {stat = "foodDelta", baseMultiplier = -0.85},
    {stat = "iceResistance", baseMultiplier = 0.2}
  },callbacks)  
end