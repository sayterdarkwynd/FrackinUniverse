require("/scripts/vec2.lua")
require("/scripts/util.lua")

function init()

  self.timerRadioMessage = 0  -- initial delay for secondary radiomessages
    
  -- Environment Configuration --
  --base values
  self.effectCutoff = config.getParameter("effectCutoff",0)
  self.effectCutoffValue = config.getParameter("effectCutoffValue",0)
  self.baseRate = config.getParameter("baseRate",0)                
  self.baseDmg = config.getParameter("baseDmgPerTick",0)        
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)     
  self.biomeTemp = config.getParameter("biomeTemp",0)              
  
  --timers
  self.biomeTimer = self.baseRate
  self.biomeTimer2 = 1
  
  --conditionals
  self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
  self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
  self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
  self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
  self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?  


  checkEffectValid()

  script.setUpdateDelta(5)
end


--******* check effect and cancel ************
function checkEffectValid()
	  if world.entityType(entity.id()) ~= "player" then
	    deactivateVisualEffects()
	    effect.expire()
	  end
	if status.statPositive("aetherImmunity") or world.type()=="unknown" then
	  effect.expire()
	end

	-- checks strength of effect vs resistance
	if ( status.stat("cosmicResistance",0)  >= self.effectCutoffValue ) then
	  deactivateVisualEffects()
	  effect.expire()
	else
	  -- activate visuals and check stats
	    if not self.usedIntro then
	      -- activate visuals and check stats
	     world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeaether", 1.0) -- send player a warning
	      self.usedIntro = 1
	    end
	end
end

-- *******************Damage effects
function setEffectDamage()
  return ( ( self.baseDmg ) *  (1 -status.stat("cosmicResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff) * self.biomeTemp ) * (1 -status.stat("cosmicResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
  return (  self.baseRate *  math.min(   1 - math.min( status.stat("cosmicResistance",0) ),0.15))
end

-- ******** Applied bonuses and penalties
function setNightPenalty()
  if (self.biomeNight > 1) then
    self.baseDmg = self.baseDmg + self.biomeNight
    self.baseDebuff = self.baseDebuff + self.biomeNight
  end
end

function setSituationPenalty()
  if (self.situationPenalty > 1) then
    self.baseDmg = self.baseDmg + self.situationPenalty
    self.baseDebuff = self.baseDebuff + self.situationPenalty 
  end
end

function setLiquidPenalty()
  if (self.liquidPenalty > 1) then
    self.baseDmg = self.baseDmg * 2
    self.baseDebuff = self.baseDebuff + self.liquidPenalty 
  end
end

function setWindPenalty()
  self.windLevel =  world.windLevel(mcontroller.position())
  if (self.windLevel > 1) then
    self.biomeThreshold = self.biomeThreshold + (self.windLevel / 100)
  end  
end

-- ********************************

--**** Other functions
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


function isDry()
local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
	if not world.liquidAt(mouthPosition) then
	    inWater = 0
	end
end

function hungerLevel()
  if status.isResource("food") then
   return status.resource("food")
  else
   return 50
  end
end

function toHex(num)
  local hex = string.format("%X", math.floor(num + 0.5))
  if num < 16 then hex = "0"..hex end
  return hex
end


-- alert the player that they are affected
function activateVisualEffects()
  effect.setParentDirectives("fade=ff23cc=0.3")
end
function deactivateVisualEffects()
  effect.setParentDirectives("fade=ff23cc=0.0")
end

-- ice breath
function makeAlert()
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")  
end


function update(dt)
checkEffectValid()
self.biomeTimer = self.biomeTimer - dt 
self.biomeTimer2 = self.biomeTimer2 - dt 
self.timerRadioMessage = self.timerRadioMessage - dt

--set the base stats
  self.baseRate = config.getParameter("baseRate",0)                
  self.baseDmg = config.getParameter("baseDmgPerTick",0)        
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)     
  self.biomeTemp = config.getParameter("biomeTemp",0)  
  self.biomeThreshold = config.getParameter("biomeThreshold",0)    
  self.biomeNight = config.getParameter("biomeNight",0)            
  self.situationPenalty = config.getParameter("situationPenalty",0)
  self.liquidPenalty = config.getParameter("liquidPenalty",0)   
  
  self.baseRate = setEffectTime()
  
  if status.isResource("food") then
      setSituationPenalty()
      self.baseDmg = ( self.baseDmg * (status.resource("food")/40) )
      self.baseDebuff = ( self.baseDebuff * (status.resource("food")/40) )
      self.baseRate = ( self.baseRate * (status.resource("food")/40) )
  end

        -- is it nighttime or above ground? 
        if not daytime then
                setNightPenalty() 
                if (self.timerRadioMessage <= 0) then
                  if not self.usedNight then
                    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeaethernight", 1.0) -- send player a warning
                    self.timerRadioMessage = 10
                    self.usedNight = 1
                  end
		end
        end
        
  --apply damage totals
  self.damageApply = setEffectDamage()   
  self.debuffApply = setEffectDebuff() 
      
      if (self.biomeTimer <= 0) and (status.stat("maxEnergy",0) > 0) then 
      
            effect.addStatModifierGroup({
              {stat = "energyRegenPercentageRate", amount = status.stat("energyRegenPercentageRate") * (1 * -status.stat("cosmicResistance",0))  },
              {stat = "energyRegenBlockTime", amount = status.stat("energyRegenBlockTime") * (1 * -status.stat("cosmicResistance",0))  },            
              {stat = "maxEnergy", amount = util.round(-self.debuffApply)  }
            })
            makeAlert()
            activateVisualEffects()
            self.biomeTimer = self.baseRate
      end 
      
      if (status.stat("maxEnergy",0) < 20) then 
	     status.modifyResource("health", -self.damageApply * dt) 
	     if status.isResource("energy") then
	       status.modifyResource("energy", -self.damageApply * dt) 
	     end
      end  
end         

function uninit()

end