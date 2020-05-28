setName="fu_enforcerset"

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.20}
}

armorBonus={
  {stat = "liquidnitrogenImmunity", amount = 1.0},
  {stat = "darknessImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	
	handleBonuses(0,checkSetWorn(self.setBonusCheck))
end

function update(dt)
	handleBonuses(dt,checkSetWorn(self.setBonusCheck))
end

function handleBonuses(dt,on)
	if on then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		applySetEffects()
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkWeapons(not on)
end

function checkWeapons(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{}) return end

	local weaponShotgun=weaponCheck({"shotgun","assaultrifle"})

	if (weaponShotgun["primary"] and weaponShotgun["alt"]) or (weaponShotgun["twoHanded"] and weaponShotgun["primary"]) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus1,2))
	elseif weaponShotgun ["either"] then
	    effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end