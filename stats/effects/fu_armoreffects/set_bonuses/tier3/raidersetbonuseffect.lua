require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_raiderset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.075}
}
weaponBonus2={
	{stat = "critDamage", amount = 0.25}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonus2Handle=effect.addStatModifierGroup({})

	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.12})
		checkWeapons()
	end
end

function checkWeapons()
	local weapons1=weaponCheck({"pistol", "machinepistol"})
	local weapons2=weaponCheck({"dagger", "knife"})
	if weapons1["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,setBonusMultiply(weaponBonus1,2))
	elseif weapons1["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
	if weapons2["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus2Handle,weaponBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus2Handle,{})
	end
end
