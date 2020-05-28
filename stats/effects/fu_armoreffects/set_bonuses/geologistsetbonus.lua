require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_geologistset"

weaponBonus={ {stat = "powerMultiplier", effectiveMultiplier = 1.5} }

armorBonus={
	{stat = "liquidnitrogenImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "pusImmunity", amount = 1}
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

	local weapons=weaponCheck({"mininglaser"})
	if weapons["primary"] and weapons["alt"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,0.25))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end