require("/scripts/vec2.lua")

function init()
  self.biomeTemp = config.getParameter("biomeTemp",0)
  self.biomeNight = config.getParameter("biomeNight",0)
  self.biomeThreshold = config.getParameter("biomeThreshold",0)
  self.windLevel =  world.windLevel(mcontroller.position())
  self.baseDmg = config.getParameter("baseDmgPerTick",0)
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
  self.baseRate = config.getParameter("baseRate",0)
  self.biomeTimer = config.getParameter("baseRate",0)
  self.biomeTimer2= config.getParameter("baseRate",0)
  
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffect", 1.0) -- send player a warning
  self.multiply = config.getParameter("multiplyColor")
  
  self.saturation = 0  
  activateVisualEffects()
  messageCheck()
  setValues()
  self.timerRadioMessage = 0
  self.situationalPenalty = 0
  script.setUpdateDelta(5)
end

function setValues()
-- check resist level and apply modifier for effects
-- this effects how hard the environmental effects hit you in general. Note that the higher up you go in resists, the less severe effects become , until they are effectively ignorable.
  if status.stat("poisonResistance") <= 0.99 then
    self.poisonhitmod = 1.5 * 1+ (status.stat("poisonResistance",0) * 4)
  elseif status.stat("poisonResistance") <= 0.80 then
    self.poisonhitmod = 1.25 * 1+ (status.stat("poisonResistance",0) * 3.5)    
  elseif status.stat("poisonResistance") <= 0.75 then
    self.poisonhitmod = 1 * 1+ (status.stat("poisonResistance",0) * 3) 
  elseif status.stat("poisonResistance") <= 0.65 then
    self.poisonhitmod = 0.8 * 1+ (status.stat("poisonResistance",0) * 2.5)    
  elseif status.stat("poisonResistance") <= 0.50 then
    self.poisonhitmod = 0.6 * 1+ (status.stat("poisonResistance",0) * 2)
  elseif status.stat("poisonResistance") <= 0.40 then
    self.poisonhitmod = 0.4 * 1+ (status.stat("poisonResistance",0) * 1.5)    
  elseif status.stat("poisonResistance") <= 0.30 then
    self.poisonhitmod = 0.1
  elseif status.stat("poisonResistance") <= 0.10 then
    self.poisonhitmod = 0.05
  elseif status.stat("poisonResistance") <= 0.05 then
    self.poisonhitmod = 0.05       
  else
    self.poisonhitmod = 0.05
  end 
    self.poisonhitTimer = self.poisonhitmod
end

-- alert the player that they are affected
function activateVisualEffects()
  --effect.setParentDirectives("fade=cc22cc=0.5")
  animator.setParticleEmitterOffsetRegion("poisonbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("poisonbreath", true)
  
  local multiply = {255 + self.multiply[1] * status.stat("poisonResistance"), 255 + self.multiply[2] * status.stat("poisonResistance"), 255 + self.multiply[3] * status.stat("poisonResistance")}
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
self.debuffApply = (self.baseDebuff* self.biomeTemp) * (-self.poisonhitmod)
self.damageApply = ( self.baseDmg * 1- math.min(status.stat("poisonResistance"),0) ) * self.biomeTemp
self.saturation = math.floor(-self.biomeTemp * self.baseRate)

      if (status.stat("poisonResistance") < 1.0) then
             mcontroller.controlModifiers({
	         speedModifier = (-status.stat("poisonResistance"))-0.2
             })     
      end   
      
      if (self.biomeTimer <= 0) and (status.stat("poisonResistance") < 1.0) then  

           self.debuffApply = ( (self.debuffApply) * (1+self.biomeTemp) )
	   self.damageApply = ( (self.damageApply + self.situationalPenalty) * ( 1* self.biomeTemp ) )

	   status.modifyResource("health", (-self.damageApply * (1-status.stat("poisonResistance"))*self.biomeTemp ) * dt)
	   status.modifyResource("food", (-self.damageApply * (1-status.stat("poisonResistance"))) * dt)    
             

        if self.biomeTimer2 <= 0 then
            effect.addStatModifierGroup({
              {stat = "protection", amount = -self.baseDebuff  },
              {stat = "maxEnergy", amount = -(self.baseDebuff*2)  }
            })
            self.biomeTimer2 = self.poisonhitTimer *8
            makeAlert()
        end
        
	activateVisualEffects()
	if (self.timerRadioMessage <= 0) then
          messageCheck()
        else
	  self.timerRadioMessage = self.timerRadioMessage - dt        
        end
          
        self.biomeTimer = self.poisonhitTimer        
        self.biomeTimer2 = self.biomeTimer2 - dt
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
                   self.timerRadioMessage = 5
             elseif (self.hungerLevel <= 10) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry3", 1.0) -- send player a warning
                   self.timerRadioMessage = 5  
             elseif (self.hungerLevel <= 20) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry2", 1.0) -- send player a warning
                   self.timerRadioMessage = 5 
             elseif (self.hungerLevel <= 30) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry1", 1.0) -- send player a warning
                   self.timerRadioMessage = 5    
             elseif (self.hungerLevel <= 40) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry5", 1.0) -- send player a warning
                   self.timerRadioMessage = 5  
             elseif (self.hungerLevel <= 50) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry6", 1.0) -- send player a warning
                   self.timerRadioMessage = 5  
             elseif (self.hungerLevel <= 60) then
                   world.sendEntityMessage(entity.id(), "queueRadioMessage", "insanityeffecthungry7", 1.0) -- send player a warning
                   self.timerRadioMessage = 5                      
 	     end        
        end    
end

function makeAlert()
        world.spawnProjectile("poisonsmoke",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
 	animator.playSound("bolt")
end

function uninit()

end