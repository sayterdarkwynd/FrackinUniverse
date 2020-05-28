require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
--require "/scripts/status.lua"

setName="fu_densiniumsetkhe"
setEffects={"convert_energy-health_10_1-1"}

weaponList={"densinium","sniperrifle","chainsword","assaultrifle"}
weaponBonus={
	{stat = "critChance", amount = 3},
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "pressureProtection", amount = 1},
	{stat = "extremepressureProtection", amount = 1},
	
	{stat = "poisonStatusImmunity", amount = 1},
	
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1},
	
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1.0},
	
	{stat = "biomecoldImmunity", amount = 1},	
	{stat = "ffextremecoldImmunity", amount = 1},
	
	{stat = "fallDamageMultiplier", effectiveMultiplier = 0.25},
	{stat = "grit", amount=0.75}
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
		mcontroller.controlModifiers({speedModifier = 1.10})
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