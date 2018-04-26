require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_corsairset"

weaponBonus={
	{stat = "powerMultiplier", amount = 0.15}
}

armorBonus={
	{stat = "pusImmunity", amount = 0.20},
	{stat = "blacktarImmunity", amount = 0.20},
	{stat = "maxBreath", amount = 400}
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
		effect.setStatModifierGroup(
		effectHandlerList.armorBonusHandle,armorBonus)
		checkWeapons()
	end
	mcontroller.controlModifiers({
		airJumpModifier = 1.05,
		speedModifier = 1.05
	})
end

function checkWeapons()
	local weapons=weaponCheck({"assaultrifle","pistol","machinepistol"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end