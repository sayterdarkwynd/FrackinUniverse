setName="fu_reconset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.15}
  }
  
armorBonus={
      {stat = "radioactiveResistance", amount = 0.25},
      {stat = "radiationburnImmunity", amount = 1.0},
      {stat = "biomeradiationImmunity", amount = 1.0}
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

	  mcontroller.controlModifiers({
	      speedModifier = 1.05
	    })
end

function daggerCheck()
	if weaponCheck("both",{"rifle","sniperrifle"},false) then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end