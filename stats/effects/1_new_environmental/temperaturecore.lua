require("/scripts/vec2.lua")

function init()
  -- Environment Configuration --
  -- it doesn't matter what environment type. biomeTemp is universal.
  self.biomeTemp = config.getParameter("biomeTemp",0)
  
  --then, the modifier for night time effects
  self.biomeNight = config.getParameter("biomeNight",0)  
  
  -- can be used as a modifier
  self.biomeThreshold = config.getParameter("biomeThreshold",0)  
  
  -- set radiomessage base timer
  self.radioMessageTimer = 1

  -- set necessary values
  self.baseDmg = config.getParameter("baseDmgPerTick",0)   -- base damage
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0) -- debuff potency
  self.biomeTimer = config.getParameter("baseRate",0) -- tick time

  -- function calls
  activateVisualEffects()
  setValues()
  
  self.timerRadioMessage = 0
  self.situationalPenalty = 0
  script.setUpdateDelta(5)
  
end



-- universal : sets default values for element modifiers
function setValuesElement()
  self.elementHitMod = 0.05
  if status.stat("STATUSNAME") <= 0.99 then
    self.ELEMENTNAMEhitmod = 0.4 * 1+ (status.stat("radioactiveResistance",0) * 1.5) 
    self.ELEMENTNAMEhitTimer = self.radioactivehitmod
  end
end  



-- check light levels, either from light sources or sunlight itself
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



-- are they in liquid?
function isDry()
local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	if not world.liquidAt(mouthPosition) then
	    inWater = 0
	end
end





