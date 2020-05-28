require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_reptileset"

weaponBonus={
	{stat = "physicalResistance", amount = 0.1}
}
weaponBonus2={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "maxHealth", effectiveMultiplier = 1.16},
	{stat = "powerMultiplier", effectiveMultiplier = 1.16}
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

	local weaponSword=weaponCheck({"shortsword","longsword","katana","rapier","dagger"})
	local weaponShield=weaponCheck({"shield"})
	local weaponSword2=weaponCheck({"axe","shortspear"})
	
	if weaponSword["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	elseif weaponSword2["either"] and weaponShield["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus2)		
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end