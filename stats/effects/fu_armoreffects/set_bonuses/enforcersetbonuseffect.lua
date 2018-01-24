require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus1={
	{stat = "powerMultiplier", amount = 0.20}
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
local weaponShotgun=weaponCheck({"shotgun","assaultrifle"})

	if weaponShotgun["primary"] and weaponShotgun["alt"] then
            effect.setStatModifierGroup(weaponBonusHandle,weaponBonus1)
	elseif weaponShotgun ["either"] then
	    effect.setStatModifierGroup(weaponBonusHandle,weaponBonus1,0.15)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end