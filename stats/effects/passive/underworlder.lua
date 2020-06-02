require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	underWorlderEffects=effect.addStatModifierGroup({})
	self.sunIntensity = config.getParameter("sunIntensity",0)
	self.radiantWorld = 0.0
    script.setUpdateDelta(10)
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
  daytime = daytimeCheck()
  underground = undergroundCheck()
  local lightLevel = getLight()

	if (world.type() == "desertwastesdark") or (world.type() == "snowdark") or (world.type() == "magmadark") or (world.type() == "volcanicdark") or (world.type() == "arborealdark") or (world.type() == "arcticdark") or (world.type() == "icewastedark") or (world.type() == "midnight") or (world.type() == "moon_shadow") or (world.type() == "penumbra") or (world.type() == "atropusdark") or (world.type() == "infernusdark") or (world.type() == "lightless") then
	  self.radiantWorld = 0.4
	elseif (world.type() == "desert") or (world.type() == "desertwastes") or (world.type() == "moon_desert") or (world.type() == "savannah") or (world.type() == "toxic") or (world.type() == "moon_toxic") or (world.type() == "alien") or (world.type() == "magma") or (world.type() == "scorchedcity") or (world.type() == "barren") or (world.type() == "protoworld") or (world.type() == "chromatic") or (world.type() == "irradiated") then
	  self.radiantWorld = -0.4
	end
  
  if daytime then
    if underground then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.2},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.24},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.12}
	  })
    elseif lightLevel > 0 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.1},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.23},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.12}
	  })
    elseif lightLevel > 95 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.001},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.14},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.02}
	  })
    elseif lightLevel > 90 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.002},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.15},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.03}
	  })
    elseif lightLevel > 80 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.003},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.16},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.04}
	  })
    elseif lightLevel > 70 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.004},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.17},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.05}
	  })
    elseif lightLevel > 65 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.005},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.18},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.06}
	  })
    elseif lightLevel > 55 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.006},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.19},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.07}
	  })
    elseif lightLevel > 45 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.007},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.2},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.08}
	  })
    elseif lightLevel > 35 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.008},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.21},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.09}
	  })
    elseif lightLevel > 25 then
	  effect.setStatModifierGroup(underWorlderEffects, {
	  {stat = "radioactiveResistance", amount = self.sunIntensity + self.radiantWorld + 0.009},
	  {stat = "energyRegenPercentageRate", amount = self.sunIntensity + 0.22},
	  {stat = "maxHealth", amount = self.sunIntensity + 1.1}
	  })
	else
	  effect.setStatModifierGroup(underWorlderEffects,{})
	end  
  end

end

function uninit()
	effect.removeStatModifierGroup(underWorlderEffects)
end

