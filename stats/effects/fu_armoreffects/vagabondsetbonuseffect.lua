setName="fu_vagabondset"

weaponEffect={
	{stat = "powerMultiplier", amount = 0.075}
}

armorBonus={
    {stat = "fireResistance", amount = 0.15}
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
	local weapons=weaponCheck({"pistol","machinepistol"})
	if weapons["primary"] and weapon["alt"] then
		effect.setStatModifierGroup(weaponHandle,setBonusMultiply(weaponEffect,2))
	elseif weapons("either",{"pistol","machinepistol"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end