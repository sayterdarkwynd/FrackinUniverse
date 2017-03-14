require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
require "/scripts/unifiedGravMod.lua"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.25}
}


armorEffect={
	{stat = "critChance", amount = 15}
}


setName="fu_precursorset"


function init()
	self.gravityMod = config.getParameter("gravityMod",0.0)
	self.gravityNormalize = config.getParameter("gravityNorm",false)
	self.gravityBaseMod = config.getParameter("gravityBaseMod",0.0)
	--sb.logInfo(sb.printJson({self.gravityMod,self.gravityNormalize,self.gravityBaseMod}))
	unifiedGravMod.init()
	setSEBonusInit("fu_spacefarerset")
	animator.setParticleEmitterOffsetRegion("sparkles", mcontroller.boundBox())
	animator.setParticleEmitterActive("sparkles", true)
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
                unifiedGravMod.update(dt)
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