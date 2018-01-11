require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus1={
	{stat = "powerMultiplier", amount = 0.25}
}
weaponBonus2={
	{stat = "powerMultiplier", amount = 0.35}
}

armorBonus={
  {stat = "liquidnitrogenImmunity", amount = 1.0},
  {stat = "darknessImmunity", amount = 1}
}


setName="fu_enforcerset"


function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})
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
local weaponShotgun=weaponCheck({"shotgun"})
local weaponAssault=weaponCheck({"assaultrifle"})

	if weaponAssault["primary"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus1)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
	if weaponShotgun["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus2)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end