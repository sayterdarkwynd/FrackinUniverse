require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.075}
  }

armorBonus={
    {stat = "grit", amount = 0.15}
}

setName="fu_stalwartset"


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
	local weapons=weaponCheck({"spear","shortspear"})
	if (weapons["either"] and weapons["twoHanded"]) or (weapons["primary"] and weapons["alt"]) then
		effect.setStatModifierGroup(weaponHandle,setBonusMultiply(weaponEffect,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end