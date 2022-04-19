require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_infernoset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.30}
}

armorBonus={
	{stat = "fireStatusImmunity", amount = 1},
	{stat = "biomeheatImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("fireburst")
		effect.expire()
	else

		status.addEphemeralEffect("fireburst")
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"flamethrower"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end