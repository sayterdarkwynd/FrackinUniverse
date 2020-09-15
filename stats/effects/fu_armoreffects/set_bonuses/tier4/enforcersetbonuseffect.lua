require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_enforcerset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.20}
}

armorBonus={
	{stat = "liquidnitrogenImmunity", amount = 1.0},
	{stat = "darknessImmunity", amount = 1}
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
	local weaponShotgun=weaponCheck({"shotgun","assaultrifle"})

	if (weaponShotgun["primary"] and weaponShotgun["alt"]) or (weaponShotgun["twoHanded"] and weaponShotgun["primary"]) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus1,2))
	elseif weaponShotgun ["either"] then
			effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end