require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_footmanset"

armorBonus={
	{stat="shortswordMastery",amount=0.15 },
	{stat="longswordMastery",amount=0.15 },
	{stat="maceMastery",amount=0.15 },
	{stat="shieldStaminaRegen",baseMultiplier=1.17 },
	{stat="shieldBonusShield",amount=0.17 },
	{stat="perfectBlockLimitRegen",baseMultiplier=1.17 }
}

weaponBonus={
	{stat="critChance",amount=2 },
	{stat="critDamage",amount=0.15 },
	{stat="grit",amount=0.15 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "shortsword", "longsword", "mace" })
	local weapons2=weaponCheck({ "shield" })
	if weapons["either"] and weapons2["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end