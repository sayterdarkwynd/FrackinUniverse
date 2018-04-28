require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_stalkerset"

weaponBonus={
	{stat = "powerMultiplier", baseMultiplier = 1.15},
	{stat = "critChance", amount = 3}
}

armorBonus2={
	{stat = "fallDamageMultiplier", baseMultiplier = 0.25}
}

armorBonus={
	{stat = "poisonResistance", amount = 0.20},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.25}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
			
	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		checkWeapons()
	end
	mcontroller.controlModifiers({
		speedModifier = 1.08
	})
end

function checkWeapons()
	local weapons=weaponCheck({"rifle","sniperrifle","bow","crossbow"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end