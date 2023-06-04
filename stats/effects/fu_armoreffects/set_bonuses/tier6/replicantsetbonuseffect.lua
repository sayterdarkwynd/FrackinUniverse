require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_replicantset"

weaponBonus={
	{stat = "critChance", amount = 2}
}

weaponBonus2={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "gasImmunity", amount = 1},
	{stat = "shadowImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1}
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
	local weaponSword=weaponCheck({"shortsword","broadsword","rapier","longsword","katana"})

	if weaponSword["primary"] and weaponSword["alt"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus2)
	elseif weaponSword["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end