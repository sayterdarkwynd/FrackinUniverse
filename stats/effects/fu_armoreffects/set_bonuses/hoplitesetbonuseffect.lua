setName="fu_hopliteset"

weaponBonus={
	{stat = "critChance", amount = 3}
}

armorBonus={
	{stat = "critChance", amount = 2.5}
}

armorEffect={
	{stat = "grit", amount = 0.12},
	{stat = "shieldStaminaRegen", amount = 0.2},
	{stat = "protoImmunity", amount = 1.0},
	{stat = "shieldBash", amount = 10},
	{stat = "shieldBashPush", amount = 2}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)

	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})


	checkWeapons()
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		checkArmor()
	end
end

function checkArmor()
	if (world.type() == "mountainous4") or (world.type() == "mountainous3") or (world.type() == "mountainous2") or (world.type() == "mountainous") then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"shortspear", "spear"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end