require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_invaderset"

weaponBonus={
	{stat = "critChance", amount = 5},
	{stat = "powerMultiplier", effectiveMultiplier = 1.20}
}

armorEffect={
	{stat = "protoImmunity", amount = 1.0},
	{stat = "fallDamageMultiplier", effectiveMultiplier = 0.75}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("slowfall")
		effect.expire()
	else
		checkWeapons()
		status.addEphemeralEffect("slowfall")
	end
end

function checkWeapons()
	local weapons=weaponCheck({"magnorb", "magnorbs", "energy"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end