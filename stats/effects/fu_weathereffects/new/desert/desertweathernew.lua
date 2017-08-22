require("/scripts/vec2.lua")
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
  self.biomeTimer2 = (self.baseRate * (1 + status.stat("fireResistance",0)) *10)
  
  --conditionals

  self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
  self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
  self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
  self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
  self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?  
  
  checkEffectValid()
  self.gracePeriod = 10
  script.setUpdateDelta(5)
end

--******* check effect and cancel ************
function checkEffectValid()
  
  if world.entityType(entity.id()) ~= "player" then
    deactivateVisualEffects()
    effect.expire()
  end
	if (status.stat("fireResistance",0)  >= self.effectCutoffValue) or (status.statPositive("biomeheatImmunity")) or (status.statPositive("ffextremeheatImmunity")) or world.type()=="unknown" then
	  deactivateVisualEffects()
	  effect.expire()
	else
	  if (status.stat("fireResistance") <= self.effectCutoffValue) then
	    if not self.usedIntro and self.timerRadioMessage == 0 then
	      -- activate visuals and check stats
	      world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesert", 1.0) -- send player a warning
	      self.usedIntro = 1
	    end
	  end

	  	
	end
end

-- *******************Damage effects

function setEffectDamage()
  return ( ( self.baseDmg ) *  (1 -status.stat("fireResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff) * self.biomeTemp ) * (1 -status.stat("fireResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
  return (  self.baseRate *  math.min(   1 - math.min( status.stat("fireResistance",0) ),0.5))
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

--**** Alert the player
function activateVisualEffects()
  effect.setParentDirectives("fade=ff7600=0.05")
  --animator.setParticleEmitterOffsetRegion("firebreath", mcontroller.boundBox())
  --animator.setParticleEmitterActive("firebreath", true) 
end

function deactivateVisualEffects()
  effect.setParentDirectives("fade=ff7600=0.0")
  --animator.setParticleEmitterActive("firebreath", false) 
end


function makeAlert()
        world.spawnProjectile("fireinvis",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
        animator.playSound("bolt")
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
  self.damageApply = setEffectDamage()   
  self.debuffApply = setEffectDebuff() 
   
  -- environment checks
  daytime = daytimeCheck()
  underground = undergroundCheck()
  local lightLevel = getLight() 

	  if underground then
		  self.biomeTemp = self.biomeTemp / 4
		  self.gracePeriod = 60
			  if not self.usedCavernous then
			    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertunderground", 1.0) -- send player a warning
			    self.timerRadioMessage = 10  
			    self.usedCavernous = 1
			  end  
	  end
	  
  if (status.stat("fireResistance") <= self.effectCutoffValue) and (self.gracePeriod <=0) then
        if daytime and lightLevel >= 75 then
          self.situationPenalty = self.situationPenalty + 0.5
                  if not self.usedNoon then
		    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertnoon", 1.0) -- send player a warning
		    self.timerRadioMessage = 10  
		    self.usedNoon = 1
		  end
        elseif daytime and lightLevel >= 15 then
                  if not self.usedSunrise then
		    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertsunrise", 1.0) -- send player a warning
		    self.timerRadioMessage = 10  
		    self.usedSunrise = 1
		  end        
        else
          self.situationPenalty = config.getParameter("situationPenalty",0)
        end
        
	if daytime then
		-- are they in liquid?
		local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
		local mouthful = world.liquidAt(mouthposition)        
		if (world.liquidAt(mouthPosition)) and (inWater == 0) and (mcontroller.liquidId()== 1) or (mcontroller.liquidId()== 6) or (mcontroller.liquidId()== 58) or (mcontroller.liquidId()== 12) then
			setLiquidPenalty()
			if (self.timerRadioMessage <= 0) then
			  if not self.usedWater then
			    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertwater", 1.0) -- send player a warning
			    self.timerRadioMessage = 10
			    self.gracePeriod = 60
			  self.usedWater = 1
			  end
			end
		    inWater = 1
		else
		  isDry()
		end 		

	      self.damageApply = setEffectDamage()   
	      self.debuffApply = setEffectDebuff() 

	      if self.biomeTimer <= 0 and status.stat("fireResistance",0) < self.effectCutoffValue then
		  self.biomeTimer = setEffectTime()
		  self.timerRadioMessage = self.timerRadioMessage - dt  	  
	      end 

	      if status.stat("fireResistance",0) <= self.effectCutoffValue then      
		   status.modifyResource("health", -self.damageApply * dt)

		   if (status.resource("health")) <= (status.resource("health")/4) then
		     mcontroller.controlModifiers({
			 airJumpModifier = 0.85, 
			 speedModifier = 0.85 
		     })  
		   end
	      end  
	      self.biomeTimer = self.biomeTimer - dt
	else
	        self.gracePeriod = 60
		if (self.timerRadioMessage <= 0) then
		  if not self.usedNight then
		    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomedesertnight", 1.0) -- send player a warning
		    self.timerRadioMessage = 10
		    self.usedNight = 1
		  end
		end  
	end
	activateVisualEffects()
  else
	    self.gracePeriod = self.gracePeriod - dt  	
  end
      
end       

function uninit()

end