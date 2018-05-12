setName="fu_leatherset"

weaponBonus={
	{stat = "critChance", amount = 5},
	{stat = "powerMultiplier", amount = 0.05}
}

armorBonus={
	{stat = "grit", amount = 0.05},
	{stat = "maxEnergy", amount = 5}
}

armorEffect={
	{stat = "critChance", amount = 2}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

function init()
	setSEBonusInit(setName)

	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()
	checkArmor()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		
		checkWeapons()
		checkArmor()
	end
end

function checkArmor()
	if (world.type() == "garden") or (world.type() == "forest") then
		effect.setStatModifierGroup(  effectHandlerList.armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(  effectHandlerList.armorBonusHandle,{})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"bow","crossbow"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end