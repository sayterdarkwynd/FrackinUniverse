require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "critChance", amount = 5}
}

armorBonus={
	{stat = "shadowResistance", amount = 0.10}
}


setName="fu_sanguineset"

function init()
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})
			
	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
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

function 
	checkWeapons()
	local weapons=weaponCheck({"dagger","knife","whip"})
if weapons["either"] then
	effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
else
	effect.setStatModifierGroup(weaponBonusHandle,{})
end
end