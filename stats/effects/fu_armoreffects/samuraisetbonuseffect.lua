setName="fu_samuraiset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.15},
    {stat = "critChance", amount = 0.5}
  }
  
armorBonus={
    {stat = "physicalResistance", amount = 0.5}
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
	if weaponCheck("either",{"shortsword","broadsword"}) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end