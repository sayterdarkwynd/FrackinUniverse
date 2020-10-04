require "/stats/effects/fu_armoreffects/setbonuses_common.lua"
setName="fu_starkillerset"

armorBonus={
	 { stat = "maxHealth", effectiveMultiplier = 1.25},
	 { stat = "maxEnergy", effectiveMultiplier = 1.25},
	 { stat = "powerMultiplier", effectiveMultiplier = 1.25},
	 { stat = "protection", effectiveMultiplier = 1.25}
}

armorEffect={
	{stat="breathProtection",amount= 1},
	{stat= "extremepressureProtection",amount= 1},
	{stat= "waterbreathProtection",amount= 1},
	{stat = "fumudslowImmunity", amount = 1},
	{stat = "slimestickImmunity", amount = 1},
	{stat = "iceslipImmunity", amount = 1},
	{stat = "snowslowImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName)
	effectHandlerList.armorEffectHandle=effect.addStatModifierGroup(armorEffect)

	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	checkArmor()
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
	return world.timeOfDay() < 0.5
end

function undergroundCheck()
	return world.underground(mcontroller.position()) 
end

function update(dt)
	if not checkSetWorn(self.setBonusCheck) then
		effect.expire()
	else
		checkArmor()
	end
end

function checkArmor()
	daytime = daytimeCheck()
	underground = undergroundCheck()
	local lightLevel = getLight()
	if daytime and not underground then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
end
