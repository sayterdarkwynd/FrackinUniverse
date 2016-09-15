require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()

    setBonusInit("fu_reconset", {
    {stat = "ffextremeradiationImmunity", amount = 1},
    {stat = "biomeradiationImmunity", amount = 1},
    {stat = "breathProtection", amount = 1},
    {stat = "grit", amount = 0.25},
    {stat = "wetImmunity", amount = 1}
	})
	
end
