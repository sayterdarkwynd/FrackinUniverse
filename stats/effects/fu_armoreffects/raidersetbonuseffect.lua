setName="fu_raiderset"

weaponEffect={
    {stat = "critBonus", amount = 10}
  }

weaponEffect2={
    {stat = "powerMultiplier", baseMultiplier = 1.15}
  }
  
armorBonus={ }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponHandle=effect.addStatModifierGroup({})
	daggerCheck()
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		daggerCheck()
	end	
  mcontroller.controlModifiers({
      speedModifier = 1.12
    })	
end

function daggerCheck()
	if weaponCheck("both",{"dagger"},false) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	elseif weaponCheck("both",{"machinepistol","pistol"},false) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect2)		
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end