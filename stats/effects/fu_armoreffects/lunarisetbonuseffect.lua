setName="fu_lunariset"

weaponEffect={
    {stat = "critChance", amount = 15},
    {stat = "powerMultiplier", baseMultiplier = 1.15}
  }
  
armorBonus={
      {stat = "energyRegenPercentageRate", baseMultiplier = 1.25},
      {stat = "energyRegenBlockTime", baseMultiplier = 0.85},
      {stat = "cosmicResistance", amount = 0.25},
      {stat = "shadowResistance", amount = 0.20}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	weaponHandle=effect.addStatModifierGroup({})
	daggerCheck()
	armorHandle=effect.addStatModifierGroup(armorBonus)	 
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		daggerCheck()
	end
end

function daggerCheck()
	if weaponCheck("either",{"lunari"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end