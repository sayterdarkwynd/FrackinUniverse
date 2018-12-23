setName="fu_daywalkerset"

weaponBonus={
	{stat = "critChance", amount = 1.5},
	{stat = "critBonus", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat = "tarImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "fumudslowImmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1}
}

require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

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
	local weapons=weaponCheck({"longsword","rapier","katana","shortsword","dagger"})
	if weapons["either"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end