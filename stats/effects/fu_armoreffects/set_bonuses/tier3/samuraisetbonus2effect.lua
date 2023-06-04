require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_samuraiset2"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15},
	{stat = "critChance", amount = 3},
	{stat = "critDamage", amount = 0.1}
}
weaponBonus2={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15},
	{stat = "critChance", amount = 4},
	{stat = "critDamage", amount = 0.1},
	{stat = "protection", effectiveMultiplier = 1.14}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	local daggercheck=weaponCheck({"dagger"})
	local katanacheck=weaponCheck({"katana"})
	if katanacheck["either"] then
		if daggercheck["either"] then
			effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus2)
		else
			effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
		end
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end