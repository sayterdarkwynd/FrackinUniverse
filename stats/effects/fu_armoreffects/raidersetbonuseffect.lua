setName="fu_raiderset"

weaponEffect1={
    {stat = "critBonus", amount = 5}
}

weaponEffect2={
    {stat = "powerMultiplier", baseMultiplier = 1.075}
}
  
armorBonus={ }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponHandle1=effect.addStatModifierGroup({})
	weaponHandle2=effect.addStatModifierGroup({})
	checkWeapons()
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end	
  mcontroller.controlModifiers({
      speedModifier = 1.12
    })	
end

function checkWeapons()
	if weaponCheck("primary",{"dagger","knife"}) then
		effect.setStatModifierGroup(weaponHandle1,weaponEffect1)
	elseif weaponCheck("primary",{"machinepistol","pistol"}) then
		effect.setStatModifierGroup(weaponHandle1,weaponEffect2)
	else
		effect.setStatModifierGroup(weaponHandle1,{})
	end
	if weaponCheck("alt",{"dagger","knife"}) then
		effect.setStatModifierGroup(weaponHandle2,weaponEffect1)
	elseif weaponCheck("alt",{"machinepistol","pistol"}) then
		effect.setStatModifierGroup(weaponHandle2,weaponEffect2)
	else
		effect.setStatModifierGroup(weaponHandle2,{})
	end
end