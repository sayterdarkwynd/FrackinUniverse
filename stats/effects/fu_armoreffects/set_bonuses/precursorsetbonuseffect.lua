require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.25}
}

armorBonus={
	{stat = "critChance", amount = 15},
	{stat = "asteroidImmunity", amount = 1},
	{stat = "breathProtection", amount = 1}
}

setName="fu_precursorset"

function init()	
	setSEBonusInit("fu_precursorset")
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
	        status.addEphemeralEffect("gravgenfieldarmor2",5)
		checkWeapons()
	end	

end

function checkWeapons()
local weaponSword=weaponCheck({"machinepistol"})
local weaponShield=weaponCheck({"machinepistol"})

	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(weaponBonusHandle,{})
	end
end