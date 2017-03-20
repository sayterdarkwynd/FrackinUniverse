require("/scripts/vec2.lua")
function init()
if (status.stat("iceResistance",0)  >= 1.0) or status.statPositive("biomecoldImmunity") or status.statPositive("ffextremecoldImmunity") or (player.worldId() == player.ownShipWorldId()) then
  effect.expire()
end

  self.timerRadioMessage = 0  -- initial delay for secondary radiomessages
    
  -- Environment Configuration --
  --base values
  self.baseRate = config.getParameter("baseRate",0)                
  self.baseDmg = config.getParameter("baseDmgPerTick",0)        
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)     
  self.biomeTemp = config.getParameter("biomeTemp",0)              
  
  --timers
  self.biomeTimer = self.baseRate
  self.biomeTimer2 = 3
  
  --conditionals
  self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
  self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
  self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
  self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
  self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?  
  
  -- activate visuals and check stats
  if not self.usedIntro then
    world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomecold", 1.0) -- send player a warning
    self.usedIntro = 1
  end
  
  activateVisualEffects()
    
  makeAlert()  
  
  script.setUpdateDelta(5)
end


-- *******************Damage effects
function setEffectDamage()
  return ( ( self.baseDmg ) *  (1 -status.stat("iceResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff) * self.biomeTemp ) * (1 -status.stat("iceResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
  return (self.baseRate * (1 - status.stat("iceResistance",0)))
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
    self.biomeThreshold = self.biomeThreshold + (self.windlevel / 100)
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
  effect.setParentDirectives("fade=3066cc=0.6")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")   	  
end

-- ice breath
function makeAlert()
        local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
        world.spawnProjectile("iceinvis",mouthPosition,entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
end


function update(dt)
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
  self.damageApply = setEffectDamage()   
  self.debuffApply = setEffectDebuff() 
   
  -- environment checks
  daytime = daytimeCheck()
  underground = undergroundCheck()
  local lightLevel = getLight()  

      if self.biomeTimer <= 0 and status.stat("iceResistance",0) < 1.0 then
	self.biomeTimer = self.biomeTimer - dt
          -- cold wind
        
        
        if self.windLevel >= 40 then
                setWindPenalty()   
                if (self.timerRadioMessage <=0) then
                  if not self.usedWind then
                    world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomecoldwind", 1.0) -- send player a warning
                    self.timerRadioMessage = 10
                    self.usedWind = 1
                  end
		end
        end
        
        -- are they in liquid?
        local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
        local mouthful = world.liquidAt(mouthposition)        
        if (world.liquidAt(mouthPosition)) then
		setLiquidPenalty()
		if (self.timerRadioMessage <= 0) then
		  if not self.usedWater then
		    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldwater", 1.0) -- send player a warning
		    self.timerRadioMessage = 10
		    self.usedWater = 1
		  end
		end
        end
        
        -- is it nighttime or above ground? 
        if not daytime then
                setNightPenalty() 
                if (self.timerRadioMessage <= 0) then
                  if not self.usedNight then
                    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldnight", 1.0) -- send player a warning
                    self.timerRadioMessage = 10
                    self.usedNight = 1
                  end
		end
        end

	self.damageApply = setEffectDamage()   
	self.debuffApply = setEffectDebuff()  
        
            effect.addStatModifierGroup({
              {stat = "maxHealth", amount = -self.damageApply  },
              {stat = "powerMultiplier", amount = -(self.debuffApply/100 )  }
            })
            activateVisualEffects()
            self.biomeTimer = setEffectTime()
      end 
      
      if status.stat("iceResistance",0) < 1.0 then      
	     self.damageApply = self.damageApply  
	     status.modifyResource("health", -self.damageApply * dt)
	   
	   if status.isResource("food") then
	     self.debuffApply = (self.debuffApply /120) 
	     if status.resource("food") >= 2 then
	       status.modifyResource("food", -self.debuffApply * dt )
	     end
           end  
             mcontroller.controlModifiers({
	         airJumpModifier = 0.4 + status.stat("iceResistance"), 
	         speedModifier = 0.2 + status.stat("iceResistance")
             })  
      end  
      --breath
      if self.biomeTimer2 <= 0 and status.stat("iceResistance",0) < 1.0 then
        makeAlert()
        self.biomeTimer2 = 2.4
      end
        
end         

function uninit()

end