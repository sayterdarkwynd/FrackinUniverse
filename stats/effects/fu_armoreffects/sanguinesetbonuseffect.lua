setName="fu_sanguineset"

weaponBonus={
	{stat = "critChance", amount = 15}
}

armorBonus={
	{stat = "poisonResistance", amount = 0.15}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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