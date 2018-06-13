require "/stats/effects/fu_armoreffects/setbonuses_common.lua"

armorBonus={
   { stat = "maxHealth", baseMultiplier = 1.25},
   { stat = "maxEnergy", baseMultiplier = 1.25},
   { stat = "powerMultiplier", effectiveMultiplier = 1.25},
   { stat = "protection", effectiveMultiplier = 1.25}
}

armorEffect={}

setName="fu_starkillerset"

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
  local lightLevel = world.lightLevel(position)
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
