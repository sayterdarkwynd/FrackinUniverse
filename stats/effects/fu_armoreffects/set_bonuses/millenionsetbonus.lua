require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_millenionset"

weaponBonus={
	{stat = "maxHealth", effectiveMultiplier = 1.20},
	{stat="grit", amount=0.25}
}


armorBonus={
	{stat = "blacktarImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "shieldStaminaRegen", baseMultiplier = 1.30},
	{stat = "shieldBonusShield", amount = 0.30},
	{stat = "perfectBlockLimitRegen", baseMultiplier = 1.30}
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

	local weaponSword=weaponCheck({"shortsword","longsword","rapier","katana"})
	local weaponShield=weaponCheck({"shield"})
	
	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end