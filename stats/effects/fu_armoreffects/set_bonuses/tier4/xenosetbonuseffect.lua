require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_xenoset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.20}
}

armorEffect={
	{stat = "breathProtection", amount = 1.0},
	{stat = "gasImmunity", amount = 1.0},
	{stat = "liquidnitrogenImmunity", amount = 1.0},
	{stat = "biomecoldImmunity", amount = 1.0}
}

function init()
	setSEBonusInit(setName)

	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
	applyFilteredModifiers({
		airJumpModifier = 1.2
	})
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle","energy"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
