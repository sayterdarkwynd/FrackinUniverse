setName="fu_militiaset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.15}
  }
  
armorBonus={}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponHandle=effect.addStatModifierGroup({})
	checkWeapons()
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end	
end

function checkWeapons()
	if weaponCheck("either",{"shotgun","assaultrifle"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end