require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_warphunterset"
setEffects={"gravitynormalization"}

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 3.4}
}

armorBonus={
	{stat = "protoImmunity", amount = 1.0},
	{stat = "fireStatusImmunity", amount = 1.0},
	{stat = "gasImmunity", amount = 1.0},
	{stat = "iceslipImmunity", amount = 1.0},
	{stat = "pressureProtection", amount = 1},
	{stat = "extremepressureProtection", amount = 1},		
	{stat = "breathProtection", amount = 1},
	{stat = "gravrainImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	
	handleBonuses(0,checkSetWorn(self.setBonusCheck))
	effect.setParentDirectives("fade=F1EA9C;0.00?border=0;F1EA9C00;00000000")
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
	
	if (weapons["either"] and weapons["twoHanded"]) or (weapons["primary"] and weapons["alt"]) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,setBonusMultiply(weaponBonus,0.25))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
