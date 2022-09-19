require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_plebianset"

armorBonus={
	{stat="shieldStaminaRegen",baseMultiplier=1.15 },
	{stat="shieldBonusShield",amount=0.15 },
	{stat="perfectBlockLimitRegen",baseMultiplier=1.15 }
}

weaponBonus={
	{stat="maxHealth",effectiveMultiplier=1.2 },
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
	local weapons=weaponCheck({ "sword","shortsword","longsword","broadsword","rapier","katana", "mace" })
	local weapons2=weaponCheck({ "shield" })
	if weapons["either"] and weapons2["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end
