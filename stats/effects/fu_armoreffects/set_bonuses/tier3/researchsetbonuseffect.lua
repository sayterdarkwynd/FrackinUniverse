require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_researchset"

weaponBonus1={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "gasImmunity", amount = 1},
	{stat = "poisonStatusImmunity", amount = 1},
	{stat = "researchBonus", amount = 1}
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
	local weapons=weaponCheck({"magnorb"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,weaponBonus1)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonus1Handle,{})
	end
end