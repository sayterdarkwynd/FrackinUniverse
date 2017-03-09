require("/scripts/vec2.lua")
function init()

  self.timerRadioMessage = 0  -- initial delay for secondary radiomessages
    
  -- Environment Configuration --
  self.biomeTemp = config.getParameter("biomeTemp",0)              -- sets the base variable for the biome/effect
  self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
  self.baseDmg = config.getParameter("baseDmgPerTick",0)           -- damage per tick
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)     --debuff per tick
  self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
  self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
  self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
  self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?  
  
  self.baseRate = config.getParameter("baseRate",0)                -- base Timer rate
  self.biomeTimer = config.getParameter("baseRate",0)              -- same as above. pare out.
  self.biomeTimer2= (self.biomeTimer * (1 + status.stat("iceResistance",0))) * 2   --this second timer is for secondary effects (debuffs) and are much slower

  -- activate visuals and check stats
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomecold", 1.0) -- send player a warning
  activateVisualEffects()
  makeAlert()  

  script.setUpdateDelta(5)
end

function setEffectDamage()
  return ( ( self.baseDmg + self.situationPenalty + self.liquidPenalty + self.biomeNight ) *  (1 -status.stat("iceResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff + self.liquidPenalty + self.biomeNight ) * self.biomeTemp ) * (1 -status.stat("iceResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
  return (( self.biomeThreshold * self.baseRate ) * (1 +status.stat("iceResistance",0)))
end

-- alert the player that they are affected
function activateVisualEffects()
  effect.setParentDirectives("fade=3066cc=0.6")
  animator.setParticleEmitterOffsetRegion("icebreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("icebreath", true) 
end

-- we have Light checks because night is colder than day. 
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



function update(dt)
  self.damageApply = setEffectDamage()
  self.debuffApply = setEffectDebuff()
  self.baseRate = setEffectTime()
  -- environment checks
  daytime = daytimeCheck()
  underground = undergroundCheck()
  local lightLevel = getLight()  
  
  
      if self.biomeTimer <= 0 and status.stat("iceResistance") < 1.0 then
	self.timerRadioMessage = self.timerRadioMessage - dt 
	
          -- cold wind
          self.windLevel =  world.windLevel(mcontroller.position())
          sb.logInfo("wind : "..self.windLevel)
          if self.windLevel >= 20 then
                -- reapply effects when in stronger winds
                self.biomeThreshold = self.biomeThreshold * (1.15 + status.stat("iceResistance"))
  		self.damageApply = setEffectDamage()
  		self.debuffApply = setEffectDebuff()
  		self.baseRate = setEffectTime()   
  		
                if self.timerRadioMessage == 0 then
                  world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomecoldwind", 1.0) -- send player a warning
                  self.timerRadioMessage = 60
		end
          end

        -- are they in liquid?
        local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
        local mouthful = world.liquidAt(mouthposition)        
        if (world.liquidAt(mouthPosition)) then
		self.liquidPenalty = self.liquidPenalty * (1.2 + status.stat("iceResistance"))
  		self.damageApply = setEffectDamage()
  		self.debuffApply = setEffectDebuff()
  		self.baseRate = setEffectTime() 		
		if self.timerRadioMessage == 0 then
		  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldwater", 1.0) -- send player a warning
		  self.timerRadioMessage = 60
		end
        end
        
        -- is it nighttime or above ground? 
        if not daytime then
                self.biomeNight = self.biomeNight * (1.15 + status.stat("iceResistance"))
  		self.damageApply = setEffectDamage()
  		self.debuffApply = setEffectDebuff()
  		self.baseRate = setEffectTime()                 
                if self.timerRadioMessage == 0 then
                  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldnight", 1.0) -- send player a warning
                  self.timerRadioMessage = 60
		end
        end
        
        
          -- activate visuals and check stats
	  activateVisualEffects()
          makeAlert()  
            effect.addStatModifierGroup({
              {stat = "maxHealth", amount = -self.baseDebuff  },
              {stat = "powerMultiplier", amount = -(self.baseDebuff/100 )  }
            })
          self.biomeTimer = self.baseRate
      end 
        
      if status.stat("iceResistance") <=0.99 then      
	     self.damageApply = (self.damageApply /120)  
	     status.modifyResource("health", -self.damageApply * dt)
	   
	   if status.isResource("food") then
	     self.debuffApply = (self.debuffApply /20) 
	     if status.resource("food") >= 2 then
	       status.modifyResource("food", -self.debuffApply * dt )
	     end
           end  
             mcontroller.controlModifiers({
	         airJumpModifier = status.stat("iceResistance")+0.1, 
	         speedModifier = status.stat("iceResistance")+0.10 -- 0.01 is a failsafe so they are never at 0 speed
             })              
      end  
      self.biomeTimer = self.biomeTimer - dt
end         


function makeAlert()
        world.spawnProjectile("iceinvis",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
        --animator.playSound("bolt")
end


function uninit()

end