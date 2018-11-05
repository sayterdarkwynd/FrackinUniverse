setName="fu_warangelset"

weaponBonus={
	{stat = "critChance", amount = 2},
	{stat = "powerMultiplier", baseMultiplier = 3.5 }
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "pressureProtection", amount = 1},
	{stat = "extremepressureProtection", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1},
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},
	{stat = "biomecoldImmunity", amount = 1},
	{stat = "grit", amount = 1.0},
	{stat = "fallDamageMultiplier", baseMultiplier = 0.0}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"chainsword"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end

