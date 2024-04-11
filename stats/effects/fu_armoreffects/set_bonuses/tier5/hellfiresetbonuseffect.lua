require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_hellfireset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "fireStatusImmunity", amount = 1},
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("fireburst_armorsetbonus")
		status.removeEphemeralEffect("gloworange")
		effect.expire()
	else

		checkWeapons()
		status.addEphemeralEffect("gloworange")
		status.addEphemeralEffect("fireburst_armorsetbonus")
	end
end

function checkWeapons()
	local weapons=weaponCheck({"flamethrower", "hellfire"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
