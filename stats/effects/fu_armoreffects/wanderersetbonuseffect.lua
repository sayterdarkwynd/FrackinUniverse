setName="fu_wandererset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.15},
    {stat = "critBonus", amount = 10}
  }
  
armorBonus={
    {stat = "electricResistance", amount = 0.20}
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
	if weaponCheck("both",{"energy"},false) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end