setName="fu_warangelset"

armorEffect={
	{stat = "pressureProtection", amount = 1},
	{stat = "extremepressureProtection", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1},
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "grit", amount = 1.0},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.0}
}


require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)

	armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end