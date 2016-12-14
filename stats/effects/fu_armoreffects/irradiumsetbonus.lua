require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_irradiumsetbonus", {
    {stat = "ffextremeheatImmunity", amount = 1},
    {stat = "biomeheatImmunity", amount = 1},
		{stat = "fireResistance", amount = 0.35}
	})
end
