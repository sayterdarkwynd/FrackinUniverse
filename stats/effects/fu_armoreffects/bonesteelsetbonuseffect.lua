setName="fu_bonesteelset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.15}
  }
  
armorBonus={
    {stat = "physicalResistance", amount = 0.15}
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
	if weaponCheck("either",{"broadsword","shortsword"}) then--setting to either means we can have shortsword with anything else, or broadsword. setting to both means broadsword or dual wield shortswords.
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end