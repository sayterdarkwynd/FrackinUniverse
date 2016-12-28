require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_arcticparkaset", {
		{stat = "protoImmunity", amount = 1},
		{stat = "ffextremecoldImmunity", amount = 1},
		{stat = "biomecoldImmunity", amount = 1},
		{stat = "shadowImmunity", amount = 1},
		{stat = "breathProtection", amount = 1},
		{stat = "waterbreathProtection", amount = 1},
    		{stat = "slushslowImmunity", amount = 1},
    		{stat = "iceslipImmunity", amount = 1},
    		{stat = "snowslowImmunity", amount = 1},		
                {stat = "liquidnitrogenImmunity", amount = 1},
                {stat = "nitrogenfreezeImmunity", amount = 1}
	})
end
