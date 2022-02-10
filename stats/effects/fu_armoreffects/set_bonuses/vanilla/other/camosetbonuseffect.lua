require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_camosetnew"

weaponBonus={
	{stat = "critChance", amount = 4},
}

armorBonus={
	{stat = "erchiusimmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "slimefrictionImmunity", amount = 1},
	{stat = "slimeImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "fumudslowImmunity", amount = 1}
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
	local weapons=weaponCheck({"sniperrifle","rifle"})

	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end