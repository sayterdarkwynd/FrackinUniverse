require "/stats/effects/fu_armoreffects/reconstatbonus/reconstatbonus.lua"
callbacks = { { init = init, update = update, uninit = uninit } }
require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()

    setBonusInit("fu_reconset", {
      {stat = "biomeradiationImmunity", amount = 1},
      {stat = "breathProtection", amount = 1},
      {stat = "poisonResistance", amount = 0.25},
      {stat = "electricResistance", amount = 0.15}
    }, callbacks )
	
end
