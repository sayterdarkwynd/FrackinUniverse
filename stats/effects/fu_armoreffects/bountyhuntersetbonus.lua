require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_bountyhunterset", {
		{stat = "iceResistance", amount = 0.25}
	})
end
