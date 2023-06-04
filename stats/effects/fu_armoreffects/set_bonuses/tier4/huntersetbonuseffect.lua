require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_hunterset"

weaponBonus={
	{stat = "critDamage", amount = 0.06},
	{stat = "powerMultiplier", effectiveMultiplier = 1.20}
}

armorEffect={
	{stat = "maxEnergy", effectiveMultiplier = 1.10}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
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
	local weapons=weaponCheck({"rocketlauncher", "grenadelauncher"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
