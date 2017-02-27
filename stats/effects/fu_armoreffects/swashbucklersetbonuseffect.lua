setName="fu_swashbucklerset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.075}
}

weaponEffect2={
    {stat = "powerMultiplier", baseMultiplier = 1.15}
}
  
armorBonus={
    {stat = "iceResistance", amount = 0.2},
    {stat = "foodDelta", baseMultiplier = 0.8},
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
  mcontroller.controlModifiers({
      airJumpModifier = 1.08
    })
end

function checkWeapons()
	if weaponCheck("both",{"shortsword"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect2)
	elseif weaponCheck("either",{"shortsword"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end