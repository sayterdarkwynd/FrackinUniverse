require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_vagabondset"

weaponBonus1={
	{stat="powerMultiplier",effectiveMultiplier=1.15}
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
		applyFilteredModifiers({speedModifier=1.1})
	end
end

function checkWeapons()
	local weapons=weaponCheck({"pistol", "machinepistol"})
	if weapons["both"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	elseif weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,setBonusMultiply(weaponBonus1,0.5))
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end
