require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_assassiniset"

weaponBonus={
	{stat = "critChance", amount = 2}
}

armorBonus={
	{stat = "shadowImmunity", amount = 1},
	{stat = "aetherImmunity", amount = 1},
	{stat = "gasImmunity", amount = 1}
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
	local weaponSword=weaponCheck({"pistol", "machinepistol"})

	if weaponSword["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end