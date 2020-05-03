require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()

		  setBonusInit("fu_hazmatset", {
		    {stat = "biomeradiationImmunity", amount = 1},
		    {stat = "radioactiveResistance", amount = 0.5}
		  })
	
end