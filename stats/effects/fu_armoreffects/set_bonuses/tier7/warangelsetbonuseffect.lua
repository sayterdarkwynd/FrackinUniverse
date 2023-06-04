require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_warangelset"

weaponBonus={
	{stat = "critChance", amount = 2},
	{stat = "powerMultiplier", effectiveMultiplier = 2.5 }
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "pressureProtection", amount = 1},
	{stat = "extremepressureProtection", amount = 1},
	{stat = "grit", amount = 0.8},
	{stat = "fallDamageMultiplier", effectiveMultiplier = 0.2}
}

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

