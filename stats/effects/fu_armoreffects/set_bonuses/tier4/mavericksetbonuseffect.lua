require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_maverickset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.15}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})
	checkWeapons()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		applyFilteredModifiers({
			speedModifier = 1.15,
			airJumpModifier = 1.15
		})
	end
end

function checkWeapons()
	local weaponSword=weaponCheck({"armcannon"})

	if weaponSword["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
