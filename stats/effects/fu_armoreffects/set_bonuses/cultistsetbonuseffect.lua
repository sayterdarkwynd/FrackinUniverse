require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_cultistset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "insanityImmunity", amount = 1},
	{stat = "shadowImmunity", amount = 1},
	{stat = "darknessImmunity", amount = 1}
}



function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.regenHandler=effect.addStatModifierGroup({})
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
		effect.setStatModifierGroup(effectHandlerList.regenHandler,{{stat="healthRegen",amount=status.stat("maxHealth")*0.008}})
		--status.modifyResourcePercentage("health", 0.008 * dt)
	end
end

function checkWeapons()
	local weapons=weaponCheck({"staff","wand"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end