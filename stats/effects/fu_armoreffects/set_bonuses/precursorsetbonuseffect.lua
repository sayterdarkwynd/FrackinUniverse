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
  self.liquidMovementParameter = {
    gravityEnabled = true,
    gravityMultiplier = 1.5,
    airForce = 20.0,
    airFriction = 0.0,
    bounceFactor = 0.0
  } 	
	setSEBonusInit("fu_precursorset")
	effect.setParentDirectives("fade=F1EA9C;0.00?border=0;F1EA9C00;00000000")
	setSEBonusInit(setName)
	weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
	armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	--sb.logInfo("%s",_ENV)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
	    if not mcontroller.onGround() then
		mcontroller.controlParameters(self.liquidMovementParameter)
		mcontroller.setYVelocity(math.min(-2,mcontroller.yVelocity() - 1));
		--mcontroller.addMomentum({0, -80*dt})
	    end	
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