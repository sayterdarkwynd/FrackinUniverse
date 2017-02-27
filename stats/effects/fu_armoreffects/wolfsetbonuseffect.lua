setName="fu_wolfset"

weaponEffect={
	{stat = "critBonus", amount = 10}
}
  
weaponEffect2={
	{stat = "critBonus", amount = 20}
}

armorBonus={
    {stat = "iceResistance", amount = 0.50},
    {stat = "iceStatusImmunity", amount = 1},
    {stat = "snowslowImmunity", amount = 1}
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
	if weaponCheck("primary",{"dagger","knife"}) and weaponCheck("alt",{"dagger","knife"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect2)
	elseif weaponCheck("either",{"dagger","knife"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end