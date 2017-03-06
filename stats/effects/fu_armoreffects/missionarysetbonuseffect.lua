setName="fu_missionaryset"

weaponEffect={
	{stat = "powerMultiplier", baseMultiplier = 1.25}
}
  
armorBonus={
    {stat = "grit", amount = 0.25},
    {stat = "critBonus", amount = 15}
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
	mcontroller.controlModifiers({
		speedModifier = 1.10
		airJumpModifier = 1.10
	})
end

function checkWeapons()
	local weapons=weaponCheck({"fist","quarterstaff"})
	if weapons["both"] or weapons["twoHanded"] then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end