require("/scripts/vec2.lua")
function init()
  -- Environment Configuration --

  --first, the modifier for temperature
  self.biomeTemp = config.getParameter("biomeTemp",0)
  
  --then, the modifier for night time effects
  self.biomeNight = config.getParameter("biomeNight",0)
  
  -- what is critical temperature threshold? This value is used to determine chance of catching hypothermia
  self.biomeThreshold = config.getParameter("biomeThreshold",0)
  
  -- now we set the base effect config
  self.radioMessageTimer = 10
  self.biomeTimer = 5
  self.baseDmg = config.getParameter("baseDmgPerTick",2)
  self.baseDebuff = config.getParameter("baseDebuffPerTick",2)
  self.baseTimer = config.getParameter("baseRate",0.5)
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeheat", 1.0) -- send player a warning
  -- set values, activate effects
  activateVisualEffects()
  setValues()
  self.timerRadioMessage = 0
  self.liquidMod = 1
  self.situationalPenalty = 0
  self.nightPenalty = 1
  script.setUpdateDelta(5)
end

function setValues()
-- check resist level and apply modifier for effects
-- this effects how hard the environmental effects hit you in general. Note that the higher up you go in resists, the less severe effects become , until they are effectively ignorable.
  if status.stat("fireResistance") <= 0.99 then
    self.firehitmod = 2 * 1+ (status.stat("fireResistance",0) * 4)
  elseif status.stat("fireResistance") <= 0.80 then
    self.firehitmod = 2 * 1+ (status.stat("fireResistance",0) * 3.5)    
  elseif status.stat("fireResistance") <= 0.75 then
    self.firehitmod = 2 * 1+ (status.stat("fireResistance",0) * 3) 
  elseif status.stat("fireResistance") <= 0.65 then
    self.firehitmod = 2 * 1+ (status.stat("fireResistance",0) * 2.5)    
  elseif status.stat("fireResistance") <= 0.50 then
    self.firehitmod = 2 * 1+ (status.stat("fireResistance",0) * 2)
  elseif status.stat("fireResistance") <= 0.40 then
    self.firehitmod = 1 * 1+ (status.stat("fireResistance",0) * 1.5)    
  elseif status.stat("fireResistance") <= 0.30 then
    self.firehitmod = 0.6
  elseif status.stat("fireResistance") <= 0.10 then
    self.firehitmod = 0.2
  elseif status.stat("fireResistance") <= 0.05 then
    self.firehitmod = 0.05       
  end 
  self.firehitTimer = self.firehitmod +1
end

-- alert the player that they are affected
function activateVisualEffects()
  effect.setParentDirectives("fade=cc66cc=0.6")
  animator.setParticleEmitterOffsetRegion("firebreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("firebreath", true) 
end


function undergroundCheck()
	return world.underground(mcontroller.position()) 
end


function update(dt)
         -- being hot also consumes energy faster , but only below 70% protection
	 if (status.isResource("energy")) and (status.stat("fireResistance",0) <= 0.7 ) then
	   status.modifyResource("energy", (status.resource("energy") * (-1 -status.stat("fireResistance")))  ) 
	 end	
	 
      -- environment checks
      underground = undergroundCheck()
      
      self.biomeTimer = self.biomeTimer - dt 
      self.debuffApply = (self.baseDebuff* self.biomeTemp) * (-self.firehitmod) 
      self.damageApply = ( self.baseDmg * 1- math.min(status.stat("fireResistance"),0) ) * self.biomeTemp

      if self.biomeTimer <= 0 and status.stat("fireResistance") < 1.0 then


        -- first we check how windy it is
        self.windLevel =  world.windLevel(mcontroller.position())
        
        -- and if they are on the surface, we give them a penalty thanks to surface conditions
        if not underground then 
          self.situationalPenalty = (self.firehitmod) * (1+ (self.windLevel/100)) 
        else
                if self.timerRadioMessage == 0 then
                  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeheatcavern", 1.0) -- send player a warning
                  self.timerRadioMessage = 60
		end        
          self.situationalPenalty = (self.firehitmod) * (2+ (self.windLevel/100))
        end 


        -- final Damage calculation
        self.damageApply = ( (self.damageApply) + (self.situationalPenalty) ) * ( (self.liquidMod) + (self.nightPenalty) )
        
         -- damage application per tick
          status.applySelfDamageRequest ({
            damageType = "IgnoresDef",
            damage = self.damageApply,
            damageSourceKind = "fire",
            sourceEntityId = entity.id()	
          })   
          
          

          -- activate visuals and check stats
	  activateVisualEffects()
	  
	  -- set the timers
          self.biomeTimer = self.firehitTimer
          self.timerRadioMessage = self.timerRadioMessage - dt
          
      end 
      
      -- and finally, the colder you get the slower you move and the crappier your jump becomes
      -- this is outside of the timer, because it needs to always apply if you have less than 100% resist, not just onTick    
      if status.stat("fireResistance") < 0.9 then
             mcontroller.controlModifiers({
	         airJumpModifier = status.stat("fireResistance")+0.1, 
	         speedModifier = status.stat("fireResistance")+0.10 -- 0.01 is a failsafe so they are never at 0 speed
             })      
      end  

        --sb.logInfo("liquid mod "..self.liquidMod)
        --sb.logInfo("nightvalue "..self.nightPenalty)
        --sb.logInfo("situational "..self.situationalPenalty)
        --sb.logInfo("damage : "..self.damageApply)      
end       

function uninit()

end