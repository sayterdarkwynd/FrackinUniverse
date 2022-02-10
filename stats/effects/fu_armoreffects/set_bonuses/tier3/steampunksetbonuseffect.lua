require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_steampunkset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.2},
	{stat = "maxEnergy", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "electricStatusImmunity", amount = 1},
	{stat = "fireStatusImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		mcontroller.controlModifiers({speedModifier = 1.05})
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"energy", "electric", "tesla"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end