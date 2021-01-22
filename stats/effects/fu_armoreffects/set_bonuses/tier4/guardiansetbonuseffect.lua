require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_guardianset"

weaponBonus={
	{stat = "grit", amount = 0.25}
}
weaponBonus2={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "shieldBash", amount = 20},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.25},
	{stat = "shieldBonusShield", amount = 0.25}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonusHandle2=effect.addStatModifierGroup({})
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
	local weaponShield=weaponCheck({"shield"})
	local weaponMace=weaponCheck({"mace"})

	if weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
	if weaponMace["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle2,weaponBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle2,{})
	end
end