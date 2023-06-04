require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_boneset"

armorBonus={
	{stat="maxHealth",effectiveMultiplier=1.05 },
	{stat="fallDamageMultiplier",effectiveMultiplier=0.85 }
}

weaponBonus={
	{stat="powerMultiplier",effectiveMultiplier=1.15 }
}

biomeBonus={
	{stat="maxHealth",effectiveMultiplier=1.05 },
	{stat="powerMultiplier",effectiveMultiplier=1.05 },
	{stat="physicalResistance",amount=0.05 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})

	checkWeapons()
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		checkArmor()
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "longsword", "axe" })
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end

function checkArmor()
	if checkBiome({ "garden", "forest" }) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,biomeBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end