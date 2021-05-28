require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_silverarmorsetnew"

weaponBonus={
	{stat = "critChance", amount = 2},
	{stat = "powerMultiplier", effectiveMultiplier = 1.1}
}

armorBonus={
	{stat = "fallDamageMultiplier", effectiveMultiplier = 0.75}
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
	local weapons=weaponCheck({"chakram","boomerang"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
