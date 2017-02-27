setName="fu_slimeset"

weaponEffect={
    {stat = "critChance", amount = 12},
    {stat = "powerMultiplier", baseMultiplier = 1.20}
  }
  
armorBonus={
	    {stat = "wetImmunity", amount = 1},
	    {stat = "poisonResistance", amount = 0.35},
	    {stat = "poisonStatusImmunity", amount = 1},
	    {stat = "slimestickImmunity", amount = 1},
	    {stat = "slimefrictionImmunity", amount = 1},
	    {stat = "slimeImmunity", amount = 1},
	    {stat = "snowslowImmunity", amount = 1},
	    {stat = "iceslipImmunity", amount = 1},
	    {stat = "mudslowImmunity", amount = 1}
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
	if weaponCheck("either",{"slime"}) then
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end