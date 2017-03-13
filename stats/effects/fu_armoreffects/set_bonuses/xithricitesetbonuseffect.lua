setName="fu_xithriciteset"

armorEffect={
	{stat = "breathProtection", amount = 1},
		{stat = "waterbreathProtection", amount = 1},
		{stat = "pressureImmunity", amount = 1},
		{stat = "shadowImmunity", amount = 1},
		{stat = "insanityImmunity", amount = 1},
		{stat = "ffextremeradiationImmunity", amount = 1},
		{stat = "radiationburnImmunity", amount = 1},
		{stat = "biomeradiationImmunity", amount = 1}

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