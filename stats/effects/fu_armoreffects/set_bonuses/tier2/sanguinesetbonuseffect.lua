require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_sanguineset"

weaponBonus={
	{stat = "critChance", amount = 4},
	{stat = "fuLeechPercent", amount = 0.005}
}
armorBonus={
	{stat = "fuLeechPercent", amount = 0.005}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		--setRegen(0)
		effect.expire()
	else
		applyFilteredModifiers({speedModifier = 1.10})
		checkWeapons()
		--setRegen(0.005)
	end
end

function checkWeapons()
	local weapons=weaponCheck({"dagger", "knife", "whip", "flail"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
