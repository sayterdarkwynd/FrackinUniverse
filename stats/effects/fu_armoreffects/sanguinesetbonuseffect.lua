setName="fu_sanguineset"

weaponEffect={
    {stat = "critChance", amount = 15}
  }
  
armorBonus={
    {stat = "poisonResistance", amount = 0.15}
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
		status.removeEphemeralEffect( "regenerationsanguine" )
	else
		checkWeapons()
		status.addEphemeralEffect( "regenerationsanguine" )
	  mcontroller.controlModifiers({
	      speedModifier = 1.1
	    })
	end	
end

function checkWeapons()
	local weapons=weaponCheck({"dagger","knife","whip"})
	if weapon["either"] then
		effect.setStatModifierGroup(weaponHandle,weaponEffect)
	else
		effect.setStatModifierGroup(weaponHandle,{})
	end
end