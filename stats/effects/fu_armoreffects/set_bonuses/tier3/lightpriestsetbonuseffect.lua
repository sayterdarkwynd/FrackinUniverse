require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_lightpriestset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.2}
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
		setRegen(0.004)
	end
end

function checkWeapons()
	local weapons=weaponCheck({"staff", "wand", "quarterstaff"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end