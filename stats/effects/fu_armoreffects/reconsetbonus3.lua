require "/stats/effects/fu_armoreffects/reconstatbonus/reconstatbonus3.lua"
callbacks = { { init = init, update = update, uninit = uninit } }
require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()

    setBonusInit("fu_reconset3", {
    {stat = "ffextremeradiationImmunity", amount = 1},
    {stat = "biomeradiationImmunity", amount = 1},
    {stat = "radiationburnImmunity", amount = 1},
    {stat = "breathProtection", amount = 1},
    {stat = "grit", amount = 0.25},
    {stat = "wetImmunity", amount = 1},
    {stat = "poisonResistance", amount = 0.25},
    {stat = "radioactiveResistance", amount = 0.4}
	},callbacks)

end
