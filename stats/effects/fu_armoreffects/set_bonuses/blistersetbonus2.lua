require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_blisterset2"
setEffects={"glowyellow"}

weaponList={"blister","bioweapon"}
weaponBonus={
	{stat = "critChance", amount = 4},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

armorBonus={ 
	{stat = "poisonStatusImmunity", amount = 1.0},
	{stat = "protoImmunity", amount = 1.0},
	{stat = "pusImmunity", amount = 1.0},
	{stat = "liquidnitrogenImmunity", amount = 1.0}
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

	local weapons=weaponCheck(weaponList)
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end

