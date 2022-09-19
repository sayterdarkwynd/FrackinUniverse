require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
require "/stats/effects/fu_statusUtil.lua"

setName="fu_daywalkerset"

weaponBonus={
	{stat = "critChance", amount = 1.5},
	{stat = "critDamage", amount = 0.25}
}

armorBonus={
	{stat = "tarImmunity", amount = 1},
	{stat = "blacktarImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "fumudslowImmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1},
	{stat = "slushslowImmunity", amount = 1},
	{stat = "maxEnergy", effectiveMultiplier = 1.05}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)

	if not world.entityExists(entity.id()) then return end
	getLight()
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else

		checkWeapons()
	end
	local daytime = daytimeCheck()
	local underground = undergroundCheck()
	local lightLevel = getLight()

	if daytime and not underground and lightLevel > 50 then
		if (self.species == "nightar") then
		    effect.setStatModifierGroup(nightarDarkHunterEffects3, {{stat = "reducePenalty", amount = 0.7 }})
		elseif (self.species == "shadow") then
			effect.removeStatModifierGroup(nightarDarkHunterEffects)
		end
	end
end



function checkWeapons()
	local weapons=weaponCheck({"sword","shortsword","longsword","broadsword","rapier","katana"})
	if weapons["either"] and not weapons["twoHanded"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end
