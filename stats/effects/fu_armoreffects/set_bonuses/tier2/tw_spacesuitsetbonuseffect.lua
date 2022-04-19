require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_tw_spacesuitset"

armorBonus={
	{stat="maxBreath",effectiveMultiplier=2.0 }
}

weaponBonus={
	{stat="powerMultiplier",effectiveMultiplier=1.12 }
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
	end
end

function checkWeapons()
	local weapons=weaponCheck({ "longsword","energy" })
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end