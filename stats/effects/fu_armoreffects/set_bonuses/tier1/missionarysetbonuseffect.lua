require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_missionaryset"

armorBonus={
	{stat="critDamage",amount=0.05 }
}

weaponBonus1={
	{stat="powerMultiplier",effectiveMultiplier=1.15 }
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonus1Handle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkWeapons()
		applyFilteredModifiers({speedModifier=1.05,airJumpModifier=1.05})
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "quarterstaff","fist" })
	if (weapons["either"] and (weapons["twoHanded"] or weapons["both"])) then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end
