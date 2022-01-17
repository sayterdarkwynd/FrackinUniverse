require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_assaultset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.2}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1}
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
		mcontroller.controlModifiers({airJumpModifier = 1.2})

		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle","energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end