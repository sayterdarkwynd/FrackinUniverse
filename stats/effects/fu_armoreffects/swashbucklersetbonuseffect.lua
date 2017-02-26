setName="fu_swashbucklerset"

weaponEffect={
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
      airJumpModifier = 1.08
    })
end

function daggerCheck()
	if weaponCheck("primary",{"shortsword"},false) and  weaponCheck("alt",{"shortsword"},false) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end