require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_densiniumsetkhe"

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
	{stat = "radiationburnImmunity", amount = 1},

	{stat = "biomecoldImmunity", amount = 1},
	{stat = "ffextremecoldImmunity", amount = 1},

	{stat = "fallDamageMultiplier", effectiveMultiplier = 0.25},
	{stat = "grit", amount=0.75},

	{stat = "energyRegenPercentageRate", effectiveMultiplier = 0.80},
	{stat = "energyRegenBlockTime", effectiveMultiplier = 1.2}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.specialHandler=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("convert_energy-health_10_1-1_inefficientover")
		status.removeEphemeralEffect("devaarmorpenalty")
		effect.expire()
	else
		status.addEphemeralEffect("convert_energy-health_10_1-1_inefficientover")
		status.addEphemeralEffect("devaarmorpenalty")
		applyFilteredModifiers({speedModifier = 1.15})
		checkWeapons()
	end

end

function checkWeapons()
	local weapons=weaponCheck({"densinium","sniperrifle","chainsword","assaultrifle"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
