require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_lunariset"

armorBonus={
	{stat="energyRegenPercentageRate",baseMultiplier=1.12 },
	{stat="energyRegenBlockTime",baseMultiplier=0.85 }
}

weaponBonus={
	{stat="critChance",amount=4 },
	{stat="powerMultiplier",effectiveMultiplier=1.15 }
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
	local weapons=weaponCheck({ "lunari" })
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end
