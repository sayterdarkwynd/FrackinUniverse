setName="fu_evaderset"

weaponEffect={
    {stat = "physicalResistance", amount = 0.15}
  }
  
armorBonus={
    {stat = "shieldRegen", amount = 0.25},
    {stat = "shieldHealth", amount = 0.25},
    {stat = "perfectBlockLimitRegen", baseMultiplier = 1.25}
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
	if weaponCheck("primary",{"shield"},false) or  weaponCheck("alt",{"shield"},false) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end