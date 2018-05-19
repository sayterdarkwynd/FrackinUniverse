setName="fu_queenset"

weaponBonus={
	{stat = "critChance", amount = 8},
	{stat = "critBonus", baseMultiplier = 3},
	{stat = "powerMultiplier", effectiveMultiplier = 1.2},
}

armorBonus={
	{stat = "beestingImmunity", amount = 1},
	{stat = "honeyslowImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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
		checkWeapons()
	end
	mcontroller.controlModifiers({
		speedModifier = 1.25,
		airJumpModifier = 1.15
	})
end

function checkWeapons()
	local weapons=weaponCheck({"bees"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end