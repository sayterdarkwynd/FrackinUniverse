setName="fu_reconset"

weaponEffect={
    {stat = "powerMultiplier", baseMultiplier = 1.15}
  }
  
armorBonus={
      {stat = "radioactiveResistance", baseMultiplier = 1.25},
      {stat = "radiationburnImmunity", baseMultiplier = 1.0},
      {stat = "biomeradiationImmunity", baseMultiplier = 1.0}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	handler=effect.addStatModifierGroup({})
        daggerCheck()
        effect.addStatModifierGroup(armorBonus)	
end

function update()
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
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end