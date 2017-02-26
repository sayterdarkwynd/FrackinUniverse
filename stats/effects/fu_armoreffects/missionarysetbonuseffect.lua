setName="fu_missionaryset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.25}
  }
  
armorBonus={
    {stat = "grit", baseMultiplier = 1.25},
    {stat = "critBonus", amount = 15}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponHandle=effect.addStatModifierGroup({})
	daggerCheck()
	armorHandle=effect.addStatModifierGroup(armorBonus)
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		daggerCheck()
	end	
	mcontroller.controlModifiers({
		speedModifier = 1.10
		airJumpModifier = 1.10
	})
end

function daggerCheck()
	if weaponCheck("both",{"fist","quarterstaff"},false) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end