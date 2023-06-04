require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_primusset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15},
	{stat = "critChance", amount = 3}
}

armorBonus={
	{stat = "grit", amount = 0.5}
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
	local weapons=weaponCheck({"fist"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
