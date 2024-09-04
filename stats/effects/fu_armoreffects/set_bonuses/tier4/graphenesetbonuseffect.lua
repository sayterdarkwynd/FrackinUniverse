require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_grapheneset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "electricStatusImmunity", amount = 1.0},
	{stat = "stunImmunity", amount = 1.0}
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
	applyFilteredModifiers({
		airJumpModifier = 1.05,
		speedModifier = 1.05
	})
end

function checkWeapons()
	local weapons=weaponCheck({"energy"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
