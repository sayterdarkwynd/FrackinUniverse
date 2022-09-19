require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_amberset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.10}
}

armorBonus={
	{stat = "beestingImmunity", amount = 1},
	{stat = "honeyslowImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		status.removeEphemeralEffect("thorns")
		effect.expire()
	else
		status.addEphemeralEffect("thorns")

		checkWeapons()
	end
end

function checkWeapons()
	local weapons=weaponCheck({"dagger","knife","sword","shortsword","longsword","broadsword","rapier","katana","axe","scythe","spear","shortspear"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
