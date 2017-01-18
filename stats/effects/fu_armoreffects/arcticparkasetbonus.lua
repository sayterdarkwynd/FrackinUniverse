require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setBonusInit("fu_arcticparkaset", {
		{stat = "protoImmunity", amount = 1},
		{stat = "ffextremecoldImmunity", amount = 1},
		{stat = "biomecoldImmunity", amount = 1},
		--{stat = "shadowImmunity", amount = 1}, doesn't fit really and there are quite a few other armors that do this already.
		{stat = "breathProtection", amount = 1},
		{stat = "waterbreathProtection", amount = 1},
    {stat = "slushslowImmunity", amount = 1},
    {stat = "iceslipImmunity", amount = 1},
    {stat = "snowslowImmunity", amount = 1},
    {stat = "liquidnitrogenImmunity", amount = 1},
    {stat = "nitrogenfreezeImmunity", amount = 1},
		{stat = "iceResistance", amount = 0.7},
		{stat = "iceStatusImmunity", amount = 1}
	})
end
