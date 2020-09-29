require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_diamondset"

weaponBonus={
	{stat = "powerMultiplier", effectiveMultiplier = 1.25},
	{stat = "critChance", amount = 2.5}
}

armorBonus={
	{stat = "katanaMastery", amount = 0.4},
	{stat = "sulphuricImmunity", amount = 1},
	{stat = "biooozeImmunity", amount = 1}
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
	local weaponSingle=weaponCheck({"katana","daikatana"})

	if weaponSingle["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)				
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end