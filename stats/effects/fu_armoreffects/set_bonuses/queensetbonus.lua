require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_queenset"

weaponBonus={
	{stat = "critChance", amount = 8},
	{stat = "critDamage", amount = 0.50},
	{stat = "powerMultiplier", effectiveMultiplier = 1.2},
}

armorBonus={
	{stat = "beestingImmunity", amount = 1},
	{stat = "honeyslowImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1.0},
	{stat = "biomeradiationImmunity", amount = 1.0}
}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	
	handleBonuses(0,checkSetWorn(self.setBonusCheck))
end

function update(dt)
	handleBonuses(dt,checkSetWorn(self.setBonusCheck))
end

function handleBonuses(dt,on)
	if on then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		applySetEffects()
		mcontroller.controlModifiers({speedModifier = 1.25,airJumpModifier = 1.15})
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkWeapons(not on)
end

function checkWeapons(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{}) return end

	local weapons=weaponCheck({"bees"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end