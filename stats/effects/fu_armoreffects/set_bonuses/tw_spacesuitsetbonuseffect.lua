require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("tw_spacesuitset", {
	    {stat = "maxBreath", amount = 600},
	    {stat = "breathDepletionRate", baseMultiplier = 2.0}
	})
end
