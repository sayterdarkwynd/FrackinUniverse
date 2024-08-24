require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_leatherset"

armorBonus={
	{stat="critChance",amount=1 }
}

weaponBonus={
	{stat="critChance",amount=2 },
	{stat="powerMultiplier",effectiveMultiplier=1.15 },
	{stat="bowEnergyBonus",amount=4 },
	{stat="bowAirBonus",amount=0.05 },
	{stat="bowDrawTimeBonus",amount=0.10 }
}

biomeBonus={
	{stat="maxEnergy",effectiveMultiplier=1.05 },
	{stat="grit",amount=0.05 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})
	checkWeapons()
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkArmor()
		checkWeapons()
		applyFilteredModifiers({speed=1.025})
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "bow", "crossbow" })
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end

function checkArmor()
	if checkBiome({ "garden", "forest" }) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,biomeBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end
