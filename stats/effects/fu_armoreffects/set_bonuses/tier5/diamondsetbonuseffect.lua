require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_diamondset"

weaponBonus={
	{stat = "katanaMastery", amount = 0.32}
}
armorBonus={
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "biooozeImmunity", amount = 1},
	{stat = "dodgetechBonus", amount = 0.2},
	{stat = "defensetechBonus", amount = 0.2}
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
	local weaponSingle=weaponCheck({"katana"})

	if weaponSingle["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end