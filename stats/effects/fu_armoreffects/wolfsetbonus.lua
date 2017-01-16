require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
  setBonusInit("fu_wolfset", {
    {stat = "biomecoldImmunity", amount = 1},
    {stat = "slushslowImmunity", amount = 1},
    {stat = "iceslipImmunity", amount = 1},
    {stat = "snowslowImmunity", amount = 1},
    {stat = "iceResistance", amount = 0.5},
    {stat = "iceStatusImmunity", amount = 1}
	})
end
