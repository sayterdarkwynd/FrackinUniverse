setName="fu_lightpriestset"

weaponEffect={
    {stat = "powerMultiplier", amount = 0.10}
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
	local weapons=weaponCheck({"staff","wand"})
	if weapons["both"] or weapons["twoHanded"] then
		effect.setStatModifierGroup(weaponHandle,setBonusMultiply(weaponEffect,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end