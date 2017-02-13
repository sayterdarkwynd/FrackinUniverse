require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("tw_spacesuitset", {
	    {stat = "breathProtection", amount = 1},
	    {stat = "waterbreathProtection", amount = 1}
	})
end
