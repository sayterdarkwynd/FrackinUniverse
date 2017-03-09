setName="fu_densiniumset"

armorBonus={
	{stat = "ffextremeheatImmunity", amount = 1},
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "protoImmunity", amount = 1},
	{stat = "extremepressureProtection", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "breathProtection", amount = 1},
	{stat = "physicalResistance", amount = 0.15},
	{stat = "radiationburnImmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	end
end