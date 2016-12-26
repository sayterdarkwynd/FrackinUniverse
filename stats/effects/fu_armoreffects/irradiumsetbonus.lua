require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_irradiumsetbonus", {
    {stat = "ffextremecoldImmunity", amount = 1},
    {stat = "biomecoldImmunity", amount = 1},
		{stat = "iceResistance", amount = 0.15}
		{stat = "radioactiveResistance", amount = 0.35}
	})
end
