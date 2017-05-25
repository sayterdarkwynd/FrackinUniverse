setName="fu_enforcerset"

weaponBonus1={
	{stat = "powerMultiplier", amount = 0.25}
}
weaponBonus2={
	{stat = "powerMultiplier", amount = 0.35}
}
armorBonus={
  {stat = "liquidnitrogenImmunity", amount = 1.0}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponBonusHandlePrimary=effect.addStatModifierGroup({})
	weaponBonusHandleAlt=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
	end
end

function checkWeapons()
	local knives=weaponCheck({"assaultrifle"})
	local guns=weaponCheck({"shotgun"})
	
	if knives["primary"] then
		effect.setStatModifierGroup(weaponBonusHandlePrimary,weaponBonus1)
	elseif guns["primary"] then
		effect.setStatModifierGroup(weaponBonusHandlePrimary,weaponBonus2)
	else
		effect.setStatModifierGroup(weaponBonusHandlePrimary,{})
	end
	
	if knives["alt"] then
		effect.setStatModifierGroup(weaponBonusHandleAlt,weaponBonus1)
	elseif guns["alt"] then
		effect.setStatModifierGroup(weaponBonusHandleAlt,weaponBonus2)
	else
		effect.setStatModifierGroup(weaponBonusHandleAlt,{})
	end
end