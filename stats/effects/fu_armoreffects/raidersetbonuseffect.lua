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
	weaponHandlePrimary=effect.addStatModifierGroup({})
	weaponHandleAlt=effect.addStatModifierGroup({})
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
	local knives=weaponCheck({"dagger","knife"})
	local guns=weaponCheck({"shield"})
	if knives["primary"] then
		effect.setStatModifierGroup(weaponHandlePrimary,weaponEffect1)
	elseif guns["primary"] then
		effect.setStatModifierGroup(weaponHandlePrimary,weaponEffect2)
	else
		effect.setStatModifierGroup(weaponHandlePrimary,{})
	end
	if knives["alt"] then
		effect.setStatModifierGroup(weaponHandleAlt,weaponEffect1)
	elseif guns["alt"] then
		effect.setStatModifierGroup(weaponHandleAlt,weaponEffect2)
	else
		effect.setStatModifierGroup(weaponHandleAlt,{})
	end
end