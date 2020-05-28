require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_reconset3"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.22},
	{stat = "critChance", amount = 3}
}

armorBonus={
	{stat = "ffextremeradiationImmunity", amount = 1.0},
	{stat = "radiationburnImmunity", amount = 1.0},
	{stat = "biomeradiationImmunity", amount = 1}
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
		mcontroller.controlModifiers({speedModifier = 1.15})
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkWeapons(not on)
end

function checkWeapons(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{}) return end

	local weapons=weaponCheck({"assaultrifle","sniperrifle"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end