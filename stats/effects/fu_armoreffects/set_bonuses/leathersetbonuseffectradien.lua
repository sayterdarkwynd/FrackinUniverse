setName="fu_leathersetradien"

weaponBonus={
	{stat = "maxHealth", effectiveMultiplier = 1.15}
}

armorBonus={
	{stat = "grit", amount = 0.05},
	{stat = "maxEnergy", effectiveMultiplier = 1.05}
}

armorEffect={
	{stat = "powerMultiplier", effectiveMultiplier = 1.05}
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
	local weapons=weaponCheck({"radien"})
	
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end