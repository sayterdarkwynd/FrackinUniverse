setName="fu_wandererset"

weaponEffect={
    {stat = "powerMultiplier", amount = 0.15},
    {stat = "critBonus", amount = 10}
  }
  
armorBonus={
    {stat = "electricResistance", amount = 0.20}
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
end

function checkWeapons()
	local weapons=weaponCheck({"energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end