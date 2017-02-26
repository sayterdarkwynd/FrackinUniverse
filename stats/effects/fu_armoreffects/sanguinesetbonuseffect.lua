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
	handler=effect.addStatModifierGroup({})
        daggerCheck()
	effect.addStatModifierGroup(armorBonus)	
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
		status.removeEphemeralEffect( "regenerationsanguine" )
	else
		daggerCheck()
		status.addEphemeralEffect( "regenerationsanguine" )
	  mcontroller.controlModifiers({
	      speedModifier = 1.10
	    })
	end	
end

function daggerCheck()
	if weaponCheck("both",{"dagger","whip"},false) then
		effect.setStatModifierGroup(handler,weaponEffect)
	else
		effect.setStatModifierGroup(handler,{})
	end
end