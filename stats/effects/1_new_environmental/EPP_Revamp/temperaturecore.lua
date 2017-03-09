require("/scripts/vec2.lua")

function init()


-- Core Environment Configuration
-- Temperature Core

-- biomeTemp 		   This value sets the basic "temperature" of the biome. This is effectively the core modifying value. Higher = greater effects
-- biomeThreshold          A modifying value. Rarely needed, but provided if desired
-- biomeNight              Night modifier. This is for biomes where night is different than day (deserts, ice planets)
-- windLevel               while not in init, technically, but rather for update, is listed here for posterity
-- baseDmg                 Base damage applied by the biome, per tick
-- baseDebuff              Base debuff applied by the biome, per tick
-- baseRate                Base time between ticks
-- situationalPenalty      This value is applied only as a modifier in specific situations.
-- liquidPenalty           Does liquid have a negative effect? if so, apply this value
-- affectAnimals	   Does the effect have a result on animals? Boolean.
-- comboEffect {           is this effect a combination? (ie: Poison + Heat)[boolean] If 1, then apply TWO resists, but averaged together.
--   comboEffect[1],
--   comboEffect[2] 
--   }	          
-- currentBiomeLayer	   what layer is the player currently in ? This can matter too. Cores are hotter, atmopsheres have less air...etc.
-- baseLayerMod	           penalty value imposed by this layer
-- baseLayerEffect	   this adds an ephemeral or persistent effect when in a particular layer if needed


  self.biomeTemp = config.getParameter("biomeTemp",0)
  self.biomeNight = config.getParameter("biomeNight",0)
  self.biomeThreshold = config.getParameter("biomeThreshold",0)
  self.windLevel =  world.windLevel(mcontroller.position())
  self.baseDmg = config.getParameter("baseDmgPerTick",0)
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
  self.baseRate = config.getParameter("baseRate",0)
  self.situationalPenalty = 0
  self.liquidPenalty = (config.getParameter("biomeTemp",0)/2)
  self.affectAnimals = 0
  comboEffect = { }
  
  
  -- radiomessages get spammy. We set this to make sure it lets them know right away, but we reset the timer to 60 afterwards (later). pick one. dont need both.
  self.timerRadioMessage = 1
  
  -- base timer for effects to apply. Note that it mirrors baseRate. This is intentional in case we want two uses for the same value
  -- the second timer applies only for cases where we want the biome effect to have more than one thing applied. For example, constant damage, but a debuff every 20 ticks.
  self.biomeTimer = config.getParameter("baseRate",0)
  self.biomeTimer2= config.getParameter("baseRate",0)

  script.setUpdateDelta(5)
end





function setElementInit(setElementName, setEffectStats,callbacks)
-- core hitmods
--self.hitMod["fire"]=math.huge
--self.hitMod["poison"]=math.huge
--self.hitMod["ice"]=math.huge
--self.hitMod["electric"]=math.huge
--self.hitMod["physical"]=math.huge
--self.hitMod["radioactive"]=math.huge
--self.hitMod["shadow"]=math.huge
--self.hitMod["cosmic"]=math.huge
	self.elementName = setElementName
	self.setElementCheck = { setElementName .. 'Resistance'}
	self.setEffectStats = setEffectStats
	self.callbacks = callbacks or {}
end



-- universal : sets default values for element modifiers
function setValuesElement()
  if status.stat("STATUSNAME") <= 0.99 then
    self.ELEMENTNAMEhitmod = self.baseHitMod * 1+ (status.stat("radioactiveResistance",0) * self.baseBiomeTemp) 
    self.ELEMENTNAMEhitTimer = self.radioactivehitmod
  end
end  



-- environment functions

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




-- check for core	
--if layername == "core" and Util:between(pos, layers.core.layerLevel, layers.underground3.layerLevel) then	
--	return true
--end	



function uninit()
end


