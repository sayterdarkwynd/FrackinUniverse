require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_ultrameshset"
setEffects={"swimboost2"}

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.20}
}

armorBonus={
	{stat = "shieldStaminaRegen", baseMultiplier = 1.35},
	{stat = "shieldBonusShield", amount = 0.35},
	{stat = "perfectBlockLimitRegen", baseMultiplier = 1.35},
	{stat = "aetherImmunity", amount = 1},
	{stat = "extremepressureProtection", amount = 1},
	{stat = "pressureProtection", amount = 1},
	{stat = "insanityImmunity", amount = 1}
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

	local weaponSword=weaponCheck({"shortsword","rapier","katana","longsword"})
	local weaponShield=weaponCheck({"shield"})
	--local weapons=weaponCheck({"shortsword","shield"})
	
	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end