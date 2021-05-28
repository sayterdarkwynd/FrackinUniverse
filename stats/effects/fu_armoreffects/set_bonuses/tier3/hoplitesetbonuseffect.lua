require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_hopliteset"

weaponBonus1={
	{stat = "critChance", amount = 3}
}

armorBonus2={
	{stat = "critChance", amount = 2.5}
}

armorBonus={
	{stat = "grit", amount = 0.12},
	{stat = "shieldBash", amount = 10},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.2},
	{stat = "perfectBlockLimitRegen", baseMultiplier = 1.2},
	{stat = "shieldBashPush", amount = 2},
	{stat = "protoImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWorld()
	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWorld()
		checkWeapons()
	end
end

function checkWorld()
	if checkBiome({"mountainous", "mountainous2", "mountainous3", "mountainous4"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"spear", "shortspear"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end