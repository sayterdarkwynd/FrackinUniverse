

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
    self.powerModifier = config.getParameter("powerModifier", 0)
    setBonusInit("fu_warangelset", {
    {stat = "ffextremeradiationImmunity", amount = 1},
    {stat = "biomeradiationImmunity", amount = 1},
    {stat = "ffextremeheatImmunity", amount = 1},
    {stat = "biomeheatImmunity", amount = 1},
    {stat = "ffextremecoldImmunity", amount = 1},
    {stat = "biomecoldImmunity", amount = 1},
    {stat = "sulphuricImmunity", amount = 1},
    {stat = "fireStatusImmunity", amount = 1},
    {stat = "nitrogenfreezeImmunity", amount = 1},
    {stat = "breathProtection", amount = 1},
    {stat = "poisonStatusImmunity", amount = 1},
    {stat = "pressureProtection", amount = 1},
    {stat = "extremepressureProtection", amount = 1},
    {stat = "powerMultiplier", baseMultiplier = self.powerModifier},
    {stat = "grit", amount = 0.75},
    {stat = "wetImmunity", amount = 1},
    {stat = "radiationburnImmunity", amount = 1},
	})
end
