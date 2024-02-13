require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_blisterset"

armorBonus={
	{stat="poisonStatusImmunity",amount=1},
	{stat="protoImmunity",amount=1}
}

weaponBonus={
	{stat="critChance",amount=2 },
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
		mcontroller.controlModifiers({speedModifier = (status.statPositive("spikeSphereActive") and 1.0) or 1.05})
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "blister","bioweapon" })
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end
