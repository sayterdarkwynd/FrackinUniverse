require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_legioniiset"

weaponBonus={
	{stat = "critChance", amount = 4}
}

armorEffect={
	{stat = "grit", amount = 0.20},
	{stat = "gasImmunity", amount = 1},
	{stat = "shieldStaminaRegen", amount = 0.3}
}

function init()
	setSEBonusInit(setName)

	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		--checkArmor()
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