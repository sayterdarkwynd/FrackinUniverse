require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_agentset"

weaponBonus={
	{stat = "critChance", amount = 4}
}

armorBonus={
	{stat = "jumptechBonus", amount = 0.25},
	{stat = "dashtechBonus", amount = 0.25},
	{stat = "dodgetechBonus", amount = 0.25},
	{stat = "phasetechBonus", amount = 0.25}
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
		mcontroller.controlModifiers({
			airJumpModifier = 1.08,
			speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.12
		})
	end
end

function checkWeapons()
	local weaponSword=weaponCheck({"dagger", "pistol"})

	if weaponSword["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
