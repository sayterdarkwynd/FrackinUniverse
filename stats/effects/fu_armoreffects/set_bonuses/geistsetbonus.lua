require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_geistset"

weaponBonus={
	{stat = "critChance", amount = 1.5}
}

armorBonus={
	{stat = "maxHealth", effectiveMultiplier = 1.25},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "breathProtection", amount = 1}
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

	local weapons=weaponCheck({"dagger","broadsword","axe","hammer","shortsword","greataxe","spear","shortspear","quarterstaff","katana","flail","scythe","mace","longsword","daikatana"})
	
	if (weapons["either"] and weapons["twoHanded"]) or (weapons["primary"] and weapons["alt"]) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,2))
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end