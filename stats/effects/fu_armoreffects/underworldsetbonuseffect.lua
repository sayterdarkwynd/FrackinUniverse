setName="fu_underworldset"

weaponEffect={
    {stat = "critChance", amount = 6}
}

weaponEffect2={
    {stat = "critChance", amount = 12}
}
  
armorBonus={
    {stat = "electricResistance", amount = 0.15},
    {stat = "iceResistance", amount = 0.15}
}

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
	if weaponCheck("either",{"rifle"}) or weaponCheck("both",{"pistol","machinepistol"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect2)
	elseif weaponCheck("either",{"pistol","machinepistol"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end