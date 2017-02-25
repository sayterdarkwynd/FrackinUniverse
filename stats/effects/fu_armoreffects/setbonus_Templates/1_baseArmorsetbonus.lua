setName="fu_bearset"

weaponEffect={ -- if it is to have stats from weapons wielded, enter them here
    {stat = "critChance", amount = 25} 
  }
  
armorBonus={  -- whatever bonuses the armor provides go here
  {stat = "iceResistance", amount = 0.15},
  {stat = "coldimmunity", amount = 1}
  }

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	effect.addStatModifierGroup(armorBonus)
	handler=effect.addStatModifierGroup({})
	myFunction()
end

function update()
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		myFunction()  -- we can run custom functions here to make all sorts of neat shit possible
	end
end

function myFunction()
	if weaponCheck("both",{"axe","hammer"},false) then   -- weaponCheck is run in setbonuses core file)
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end