require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("tw_spacesuitset", {
	    {stat = "maxBreath", amount = 600},
	    {stat = "breathDepletionRate", baseMultiplier = 2.0},
	    {stat = "fireResistance", amount = 0.15},
	    {stat = "iceResistance", amount = 0.15},
	    {stat = "electricResistance", amount = 0.15},
	    {stat = "poisonResistance", amount = 0.15},
	    {stat = "radioactiveResistance", amount = 0.15}
	})
end
