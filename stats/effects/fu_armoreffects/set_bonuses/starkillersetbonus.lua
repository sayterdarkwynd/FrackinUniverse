require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

setName="fu_starkillerset"

armorBonus2={
   { stat = "maxHealth", effectiveMultiplier = 1.25},
   { stat = "maxEnergy", effectiveMultiplier = 1.25},
   { stat = "powerMultiplier", effectiveMultiplier = 1.25},
   { stat = "protection", effectiveMultiplier = 1.25}
}

armorBonus={
	{stat="breathProtection",amount= 1},{stat= "extremepressureProtection",amount= 1},{stat= "waterbreathProtection",amount= 1},
	{stat = "fumudslowImmunity", amount = 1},{stat = "slimestickImmunity", amount = 1},{stat = "iceslipImmunity", amount = 1},{stat = "snowslowImmunity", amount = 1}
}

function init()
	setSEBonusInit(setName,setEffects)
	effectHandlerList.armorBonus2Handle=effect.addStatModifierGroup({})
	effectHandlerList.armorBonusHandle=effect.addStatModifierGroup({})
	
	handleBonuses(0,checkSetWorn(self.setBonusCheck))
end

function update(dt)
	handleBonuses(dt,checkSetWorn(self.setBonusCheck))
end

function handleBonuses(dt,on)
	if on then
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,armorBonus)
		applySetEffects()
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonusHandle,{})
	end
	checkArmor(not on)
end

function checkArmor(autofail)
	if autofail then effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{}) return end
	
	daytime = daytimeCheck()
	underground = undergroundCheck()
	local lightLevel = getLight()
	if daytime and not underground then
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,armorBonus2)
	else
		effect.setStatModifierGroup(effectHandlerList.armorBonus2Handle,{})
	end
end

function getLight()
	local position = mcontroller.position()
	position[1] = math.floor(position[1])
	position[2] = math.floor(position[2])
	local lightLevel = world.lightLevel(position)
	lightLevel = math.floor(lightLevel * 100)
	return lightLevel
end

function daytimeCheck()
	return world.timeOfDay() < 0.5
end

function undergroundCheck()
	return world.underground(mcontroller.position()) 
end