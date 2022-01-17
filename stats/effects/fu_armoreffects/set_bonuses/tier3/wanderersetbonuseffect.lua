require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_wandererset"

armorBonus={
	{stat = "critChance", amount = 2}
}
weaponBonus={
	{stat = "critDamage", amount = 0.1},
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
	end
end

function checkWeapons()
	local energycheck=weaponCheck({"energy"})
	if energycheck["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end