setName="fu_missionaryset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorEffect={
	{stat = "critBonus", baseMultiplier = 1.5}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		
		checkWeapons()
	end
	mcontroller.controlModifiers({
		speedModifier = 1.05,
		airJumpModifier = 1.05
	})
end

function checkWeapons()
	local weapons=weaponCheck({"fist","quarterstaff"})
	if weapons["both"] or (weapons["twoHanded"] and weapons["either"]) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end