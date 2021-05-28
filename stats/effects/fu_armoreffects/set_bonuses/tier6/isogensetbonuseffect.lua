require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_isogenset"

weaponBonus={
	{stat = "physicalResistance", amount = 0.15},
	{stat = "critChance", amount = 3}
}

armorBonus={
	{stat = "breathProtection", amount = 1},
	{stat = "ffextremeheatImmunity", amount = 1},
	{stat = "lavaImmunity", amount = 1},
	{stat = "biomeheatImmunity", amount = 1},
	{stat = "fireStatusImmunity", amount = 1}
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
	local weapons=weaponCheck({"isogen"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end