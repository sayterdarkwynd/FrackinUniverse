require("/scripts/vec2.lua")

function init()

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
  self.biomeTimer2=  (self.baseRate * (1 + status.stat("poisonResistance",0)) *2)   --this second timer is for secondary effects (debuffs) and are much slower


  -- inform them they are ill                                
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomeinsanity", 1.0) -- send player a warning
  self.timerRadioMessage =  config.getParameter("baseRate",0)  -- initial delay for secondary radiomessages
  
  -- set desaturation effect
  self.multiply = config.getParameter("multiplyColor")
  self.saturation = 0  
  
  -- activate visuals
  activateVisualEffects()
  
  -- check for Hunger messages
  messageCheck()

  script.setUpdateDelta(5)
end


function setEffectDamage()
  return ( ( self.baseDmg + self.situationPenalty + self.liquidPenalty + self.biomeNight ) *  (1 -status.stat("poisonResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff + self.liquidPenalty + self.biomeNight ) * self.biomeTemp ) * (1 -status.stat("poisonResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
  return (( self.biomeThreshold * self.baseRate ) * (1 +status.stat("poisonResistance",0)))
end


-- alert the player that they are affected
function activateVisualEffects()
sb.logInfo("self.multiply")
  animator.setParticleEmitterOffsetRegion("poisonbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("poisonbreath", true)
  
  local multiply = {100 * status.stat("poisonResistance",0), 255 + self.multiply[2] * status.stat("poisonResistance",0), 255 + self.multiply[3] * status.stat("poisonResistance",0)}
  local multiplyHex = string.format("%s%s%s", toHex(multiply[1]), toHex(multiply[2]), toHex(multiply[3]))  
  effect.setParentDirectives(string.format("?saturation=%d?multiply=%s", self.saturation, multiplyHex))
end

function toHex(num)
  local hex = string.format("%X", math.floor(num + 0.5))
  if num < 16 then hex = "0"..hex end
  return hex
end


function update(dt)
-- environment checks
self.biomeTimer = self.biomeTimer - dt 
self.biomeTimer2 = self.biomeTimer2 - dt 
self.timerRadioMessage = self.timerRadioMessage - dt 
self.saturation = math.floor(-self.biomeTemp * self.baseRate)
self.damageApply = setEffectDamage()
self.debuffApply = setEffectDebuff()
self.baseRate = setEffectTime()
self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
  
      if (status.stat("poisonResistance") < 1.0) then
             mcontroller.controlModifiers({
	         speedModifier = (-status.stat("poisonResistance",0))-0.2
             })     
      end   
      
      if (self.biomeTimer <= 0) and (status.stat("poisonResistance",0) < 1.0) then  
	status.modifyResource("health", -self.damageApply * dt)
	status.modifyResource("food", -self.damageApply * dt) 
	
	activateVisualEffects()
	if (self.timerRadioMessage <= 0) then
          messageCheck()
        else
	  self.timerRadioMessage = self.timerRadioMessage - dt        
        end
        self.biomeTimer = self.baseRate       
      end
      
      if (self.biomeTimer2 <= 0) and (status.stat("poisonResistance",0) < 1.0) then
            effect.addStatModifierGroup({
              {stat = "protection", amount = -self.baseDebuff  },
              {stat = "maxEnergy", amount = -(self.baseDebuff*2)  }
            })
        makeAlert()
        self.biomeTimer2 = (self.biomeTimer * (1 + status.stat("poisonResistance",0))) * 2
      end      
end       

function hungerLevel()
  if status.isResource("food") then
   return status.resource("food")
  else
   return 50
  end
end

function messageCheck()
  self.hungerLevel = hungerLevel()
        if (self.windLevel >= 20) then
                if self.timerRadioMessage == 0 then
                  world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffectwindy", 1.0) -- send player a warning
                  self.timerRadioMessage = 5
		end
        end
        if status.isResource("food") then
	     if ( self.hungerLevel <= 5) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry4", 1.0) -- send player a warning
                   self.timerRadioMessage = 20
             elseif (self.hungerLevel <= 10) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry3", 1.0) -- send player a warning
                   self.timerRadioMessage = 20  
             elseif (self.hungerLevel <= 20) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry2", 1.0) -- send player a warning
                   self.timerRadioMessage = 20 
             elseif (self.hungerLevel <= 30) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry1", 1.0) -- send player a warning
                   self.timerRadioMessage = 20    
             elseif (self.hungerLevel <= 40) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry5", 1.0) -- send player a warning
                   self.timerRadioMessage = 20  
             elseif (self.hungerLevel <= 50) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry6", 1.0) -- send player a warning
                   self.timerRadioMessage = 20 
             elseif (self.hungerLevel <= 60) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry7", 1.0) -- send player a warning
                   self.timerRadioMessage = 20                      
 	     end        
        end    
end

function makeAlert()	
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")   	
end

function uninit()

end