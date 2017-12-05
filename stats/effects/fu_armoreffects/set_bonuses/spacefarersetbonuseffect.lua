require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 2.0}
}

armorBonus={
		{stat = "protoImmunity", amount = 1.0},
		{stat = "fireStatusImmunity", amount = 1.0},
		{stat = "gasImmunity", amount = 1.0},
		{stat = "iceslipImmunity", amount = 1.0},
		{stat = "maxBreath", amount = 1400},
		{stat = "breathDepletionRate", baseMultiplier = 1.0},
		{stat = "asteroidImmunity", amount = 1}
}

setName="fu_spacefarerset"

function init()
	setSEBonusInit("fu_spacefarerset")
	effect.setParentDirectives("fade=F1EA9C;0.00?border=0;F1EA9C00;00000000")
	
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
	       -- status.addEphemeralEffect("gravgenfieldarmor",5)
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"mininglaser"})
	if weapons["primary"] and weapons["alt"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	elseif weapons["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,setBonusMultiply(weaponBonus,0.25))
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end