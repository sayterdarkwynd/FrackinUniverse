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
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"xithricite"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end