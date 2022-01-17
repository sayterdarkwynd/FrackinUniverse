require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_warriorset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.10}
}

armorBonus={
	{stat = "maxHealth", effectiveMultiplier = 1.10}
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
		mcontroller.controlModifiers({
			speedModifier = 1.10
		})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"melee","shortsword","broadsword","whip","axe","hammer","spear","shortspear","dagger","longsword","rapier","mace","scythe","quarterstaff","katana","daikatana"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end