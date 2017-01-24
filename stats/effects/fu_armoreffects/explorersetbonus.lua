require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_explorerset", {
		{stat = "iceResistance", amount = 0.15},
                {stat = "biomecoldImmunity", amount = 1}
	})
end
