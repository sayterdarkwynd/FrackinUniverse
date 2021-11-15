require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
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
	{stat = "maxEnergy", effectiveMultiplier = 1.1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.weaponBonusHandle=effect.addStatModifierGroup({})

	checkWeapons()

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup(armorBonus)

	if not world.entityExists(entity.id()) then return end
	getLight()
end

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = math.min(world.lightLevel(position),1.0)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function daytimeCheck()
	return world.timeOfDay() < 0.5 -- true if daytime
end

function undergroundCheck()
	return world.underground(mcontroller.position())
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
	local weapons=weaponCheck({"longsword","rapier","katana","shortsword","dagger"})
	if weapons["either"] and not weapons["twoHanded"] then
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,weaponBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.weaponBonusHandle,{})
	end
end