require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_survivorset"

weaponBonus={
	{stat = "critDamage", amount = 0.06},
	{stat = "powerMultiplier", effectiveMultiplier = 1.20}
}

armorEffect={
	{stat = "foodDelta", baseMultiplier = 0.5},
	{stat = "protoImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1}
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
	else
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"rocketlauncher", "grenadelauncher", "bow", "crossbow"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end