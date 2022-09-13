require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_sentryset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "maxEnergy", effectiveMultiplier = 1.15},
	{stat = "maxHealth", effectiveMultiplier = 1.15}
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
	local weaponsEnergy=weaponCheck({"energy"})
	local weaponsRifle=weaponCheck({"rifle","assaultrifle","sniperrifle"})
	if weaponsEnergy["either"] and weaponsRifle["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
