require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_intrepidset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.2},
	{stat = "critChance", amount = 2}
}

armorBonus={
	{stat = "grit", amount = 0.15}
}

armorBonus2={
	{stat = "grit", amount = 0.12}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})

	checkWeapons()
	checkWorld()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		checkWorld()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"hammer", "flail"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end

function checkWorld()
	if checkBiome({"mountainous", "mountainous2", "mountainous3", "mountainous4"}) then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end