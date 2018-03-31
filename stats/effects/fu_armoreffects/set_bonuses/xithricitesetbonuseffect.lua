require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_xithriciteset"

weaponBonus={
  {stat = "critChance", amount = 3}
}

armorBonus={
		{stat = "breathProtection", amount = 1},
		{stat = "waterbreathProtection", amount = 1},
		{stat = "pressureProtection", amount = 1},
		{stat = "extremepressureProtection", amount = 1},
		{stat = "shadowImmunity", amount = 1},
		{stat = "insanityImmunity", amount = 1},
		{stat = "ffextremeradiationImmunity", amount = 1},
		{stat = "radiationburnImmunity", amount = 1},
		{stat = "biomeradiationImmunity", amount = 1},
		{stat = "aetherImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})
			
	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		effect.setStatModifierGroup(
		armorBonusHandle,armorBonus)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"xithricite"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end