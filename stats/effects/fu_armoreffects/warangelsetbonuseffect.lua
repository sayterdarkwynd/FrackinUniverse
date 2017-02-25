setName="fu_warangelset"

armorBonus={
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
    {stat = "grit", amount = 0.75},
    {stat = "wetImmunity", amount = 1},
    {stat = "radiationburnImmunity", amount = 1},
    {stat = "powerMultiplier", baseMultiplier = 1.25}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end