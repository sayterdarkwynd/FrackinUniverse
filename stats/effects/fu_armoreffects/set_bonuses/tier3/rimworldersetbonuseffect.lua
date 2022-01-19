require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_rimworlderset"

armorBonus={
	{stat = "sandstormImmunity", amount = 1},
	{stat = "stunImmunity", amount = 1},
	{stat = "electricStatusImmunity", amount = 1}
}

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.2},
	{stat = "critChance", amount = 3},
	{stat = "bowEnergyBonus", amount = 6},
	{stat = "bowDrawTimeBonus", amount = 0.15}
}
weaponBonus2={{stat = "powerMultiplier", effectiveMultiplier = 1.25}}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle1=effect.addStatModifierGroup({})
	effectHandlerList.weaponBonusHandle2=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
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
	local hasBow=weaponCheck({"bow"})
	local hasOthers=weaponCheck({"sniperrifle", "spear", "shortspear", "lance"})
	if hasBow["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle1,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle1,{})
	end
	if hasOthers["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle2,weaponBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle2,{})
	end

end