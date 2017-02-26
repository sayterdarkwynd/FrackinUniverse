setName="fu_lunariset"

weaponEffect={
    {stat = "critChance", amount = 15},
    {stat = "powerMultiplier", baseMultiplier = 1.15}
  }
  
armorBonus={
      {stat = "energyRegenPercentageRate", baseMultiplier = 1.25},
      {stat = "energyRegenBlockTimee", baseMultiplier = 0.85},
      {stat = "cosmicResistance", baseMultiplier = 1.25},
      {stat = "shadowResistance", baseMultiplier = 1.20}
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
end

function daggerCheck()
	if weaponCheck("both",{"lunari"},false) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end