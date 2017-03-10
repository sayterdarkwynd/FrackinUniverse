require("/scripts/vec2.lua")
function init()

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
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomecold", 1.0) -- send player a warning
  activateVisualEffects()
  makeAlert()  
  script.setUpdateDelta(5)
end

function resetValues()
  self.biomeTemp = config.getParameter("biomeTemp",0)              -- sets the base variable for the biome/effect
  self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
  self.baseDmg = config.getParameter("baseDmgPerTick",0)           -- damage per tick
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)     --debuff per tick
  self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
  self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
  self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
  self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?  
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

function setNightPenalty()
  self.modDmg = self.baseDmg + self.biomeNight
  self.modDebuff = self.baseDebuff + self.biomeNight 
  self.baseDmg = self.damageApply + self.modDmg
  self.baseDebuff = self.debuffApply + self.modDebuff
end

function setSituationPenalty()
  self.modDmg = self.baseDmg + self.situationPenalty
  self.modDebuff = self.baseDebuff + self.situationPenalty
  self.baseDmg = self.damageApply + self.modDmg
  self.baseDebuff = self.debuffApply + self.modDebuff 
end

function setLiquidPenalty()
  self.modDmg = self.baseDmg + self.liquidPenalty
  self.modDebuff = self.baseDebuff + self.liquidPenalty
  self.baseDmg = self.damageApply + self.modDmg
  self.baseDebuff = self.debuffApply + self.modDebuff
end

function setWindPenalty()
  self.windLevel =  world.windLevel(mcontroller.position())
  self.modThreshold = (self.windlevel / 100) + self.biomeThreshold
  self.biomeThreshold = self.biomeThreshold + self.modThreshold  
end

-- ********************************


-- alert the player that they are affected
function activateVisualEffects()
  effect.setParentDirectives("fade=3066cc=0.6")
  --animator.setParticleEmitterOffsetRegion("icebreath", mcontroller.boundBox())
  --animator.setParticleEmitterActive("icebreath", true)
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")   	  
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
self.biomeTimer = self.biomeTimer - dt 
self.biomeTimer2 = self.biomeTimer2 - dt 
sb.logInfo("minus: "..self.biomeTimer2)
self.timerRadioMessage = self.timerRadioMessage - dt

--set the base stats
self.damageApply = setEffectDamage()
self.debuffApply = setEffectDebuff()
self.baseRate = setEffectTime()
sb.logInfo("resist : "..status.stat("iceResistance",0))
sb.logInfo("first timer : "..self.baseRate)

  -- environment checks
  daytime = daytimeCheck()
  underground = undergroundCheck()
  local lightLevel = getLight()  

      if self.biomeTimer <= 0 and status.stat("iceResistance",0) < 1.0 then
	self.timerRadioMessage = self.timerRadioMessage - dt 
	self.biomeTimer = self.biomeTimer - dt
          -- cold wind
        
        if self.windLevel >= 40 then
                if self.timerRadioMessage == 0 then
                  world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomecoldwind", 1.0) -- send player a warning
                   self.timerRadioMessage = 60
                   setWindPenalty()
		end
        end
        
        -- are they in liquid?
        local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
        local mouthful = world.liquidAt(mouthposition)        
        if (world.liquidAt(mouthPosition)) then
		setLiquidPenalty()	
		if self.timerRadioMessage == 0 then
		  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldwater", 1.0) -- send player a warning
		  self.timerRadioMessage = 60
		end
        end
        
        -- is it nighttime or above ground? 
        if not daytime then
                setNightPenalty()                
                if self.timerRadioMessage == 0 then
                  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldnight", 1.0) -- send player a warning
                  self.timerRadioMessage = 60
		end
        end
 
        
            effect.addStatModifierGroup({
              {stat = "maxHealth", amount = -self.debuffApply  },
              {stat = "powerMultiplier", amount = -(self.debuffApply/100 )  }
            })
            activateVisualEffects()
            sb.logInfo("timer in biomeTimer function: "..self.biomeTimer)
            self.biomeTimer = setEffectTime()
            sb.logInfo("reset timer after that function : "..self.biomeTimer)
            
      end 
      
      if status.stat("iceResistance",0) < 1.0 then      
	     self.damageApply = (self.damageApply /120)  
	     status.modifyResource("health", -self.damageApply * dt)
	   
	   if status.isResource("food") then
	     self.debuffApply = (self.debuffApply /50) 
	     if status.resource("food") >= 2 then
	       status.modifyResource("food", -self.debuffApply * dt )
	     end
           end  
             mcontroller.controlModifiers({
	         airJumpModifier = 1 * status.stat("iceResistance")+0.1, 
	         speedModifier = 1 * status.stat("iceResistance")+0.1
             })  
      end  
      --breath
      if self.biomeTimer2 <= 0 and status.stat("iceResistance",0) < 1.0 then
        makeAlert()
        self.biomeTimer2 = 2.4
        sb.logInfo("reset value: "..self.biomeTimer2)
      end
        
end         

-- ice breath
function makeAlert()
        local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
        world.spawnProjectile("iceinvis",mouthPosition,entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
end


function uninit()

end