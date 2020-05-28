require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_guardianset"

weaponBonus={
	{stat = "grit", amount = 0.25}
}

weaponBonus2={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "shieldBash", amount = 20},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.25},
	{stat = "shieldBonusShield", amount = 0.25}
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
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkWeapons(not on)
end

function checkWeapons(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{}) return end
	
	local weaponShield=weaponCheck({"shield"})
	local weaponMace=weaponCheck({"mace"})
	
	if weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
	if weaponMace["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus2Handle,weaponBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus2Handle,{})
	end	
end