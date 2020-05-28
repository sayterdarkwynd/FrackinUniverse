require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_biofleshset"

weaponBonus={ {stat = "powerMultiplier", effectiveMultiplier = 1.15} }

armorBonus={
	{stat = "pusImmunity", amount = 1},
	{stat = "energyRegenPercentageRate", baseMultiplier = 1.05},
	{stat = "energyRegenBlockTime", baseMultiplier = 0.95}
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
		mcontroller.controlModifiers({speedModifier = 1.12,airJumpModifier = 1.12})
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		applySetEffects()
		setRegen((0.01)*(((status.resourcePercentage("health") < 0.5) and 1 or 0)+((status.resourcePercentage("health") < 0.25) and 1 or 0)))
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
		setRegen(0)
	end
	checkWeapons(not on)
end

function checkWeapons(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{}) return end

	local weapons=weaponCheck({"bioweapon"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end