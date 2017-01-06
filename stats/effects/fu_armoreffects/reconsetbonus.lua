require "/stats/effects/fu_armoreffects/reconstatbonus/reconstatbonus.lua"
callbacks = { { init = init, update = update, uninit = uninit } }
require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()

    setBonusInit("fu_reconset", {
      {stat = "biomeradiationImmunity", amount = 1},
      {stat = "breathProtection", amount = 1},
      {stat = "poisonResistance", amount = 0.10},
      {stat = "radioactiveResistance", amount = 0.15},
      {stat = "radiationburnImmunity", amount = 1},
    }, callbacks )

end
