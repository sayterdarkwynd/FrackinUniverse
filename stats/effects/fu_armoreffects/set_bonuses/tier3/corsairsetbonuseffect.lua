require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_corsairset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "pusImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1},
	{stat = "maxBreathmaxBreath", amount = 400},
	{stat = "bombtechBonus", amount = 1.5}
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
		mcontroller.controlModifiers({airJumpModifier = 1.05,speedModifier = 1.05})

		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle", "pistol", "machinepistol"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end