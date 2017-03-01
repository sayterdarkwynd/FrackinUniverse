setName="fu_lightpriestset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.10}
  }
  weaponEffect2={
    {stat = "powerMultiplier", baseMultiplier = 1.20}
  }
  
armorBonus={
    { stat = "cosmicResistance", amount = 0.25 }
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
		status.modifyResourcePercentage("health", 0.004 * dt)
	end	
end

function checkWeapons()
	if weaponCheck("both",{"staff","wand"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect2)
	elseif weaponCheck("either",{"wand"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end