require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_xenoset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.20},
	{stat = "critChance", amount = 2}
}

armorBonus={
	{stat = "breathProtection", amount = 1.0},
	{stat = "gasImmunity", amount = 1.0},
	{stat = "liquidnitrogenImmunity", amount = 1.0},
	{stat = "biomecoldImmunity", amount = 1.0},
	{stat = "fallDamageMultiplier", amount = 0.70}
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
		mcontroller.controlModifiers({airJumpModifier = 1.2})
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkWeapons(not on)
end

function checkWeapons(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{}) return end

	local weapons=weaponCheck({"assaultrifle","energy"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end