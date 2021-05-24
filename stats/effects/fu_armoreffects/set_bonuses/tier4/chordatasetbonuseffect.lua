require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_chordataset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorEffect={
	{ stat = "hammerMastery", amount = 0.4 },
	{ stat = "breathProtection", amount = 1.0 },
	{ stat = "insanityImmunity", amount = 1.0 },
	{ stat = "poisonStatusImmunity", amount = 1.0 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
		status.removeEphemeralEffect("swimboost1")
	else
		checkWeapons()
		status.addEphemeralEffect("swimboost1")
	end
end

function checkWeapons()
	local weapons=weaponCheck({"spear","shortspear"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end