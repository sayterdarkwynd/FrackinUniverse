require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_radienpyreiteset"

weaponBonus={
	{stat = "protection", effectiveMultiplier = 1.1}
}

armorBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.07},
	{stat = "maxHealth", effectiveMultiplier = 1.25},
	{stat = "maxEnergy", effectiveMultiplier = 1.2},
	{stat = "breathProtection", amount = 1},
	{stat = "iceStatusImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "fireStatusImmunity", amount = 1},
	{stat = "biomeradiationImmunity", amount = 1},
	{stat = "ffextremeradiationImmunity", amount = 1},
	{stat = "radiationburnImmunity", amount = 1},
	{stat = "sulphuricImmunity", amount = 1}
}

biomeBonus={
	{stat = "grit", amount=0.05},
	{stat = "maxEnergy", effectiveMultiplier = 1.05}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.biomeBonusHandle=effect.addStatModifierGroup({})
	checkPlanet()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		checkPlanet()
		applyFilteredModifiers({
			speedModifier = 1.05
		})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"radien"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end

function checkPlanet()
	if checkBiome({"sulphuric", "sulphuricdark", "sulphuricocean"}) then
		effect.setStatModifierGroup(effectHandlerList.biomeBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.biomeBonusHandle,{})
	end
end
