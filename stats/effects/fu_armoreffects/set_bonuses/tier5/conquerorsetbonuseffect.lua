require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_conquerorset"

weaponBonus={
	{stat = "critChance", amount = 1},
	{stat = "critDamage", amount = 0.25},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1}
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
	local weapons=weaponCheck({"plasma","electric"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end