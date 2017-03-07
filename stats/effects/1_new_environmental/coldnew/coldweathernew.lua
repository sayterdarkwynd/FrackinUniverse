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
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomecold", 1.0) -- send player a warning
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
  if status.stat("iceResistance") <= 0.99 then
    self.icehitmod = 2 * 1+ (status.stat("iceResistance",0) * 4)
  elseif status.stat("iceResistance") <= 0.80 then
    self.icehitmod = 2 * 1+ (status.stat("iceResistance",0) * 3.5)    
  elseif status.stat("iceResistance") <= 0.75 then
    self.icehitmod = 2 * 1+ (status.stat("iceResistance",0) * 3) 
  elseif status.stat("iceResistance") <= 0.65 then
    self.icehitmod = 2 * 1+ (status.stat("iceResistance",0) * 2.5)    
  elseif status.stat("iceResistance") <= 0.50 then
    self.icehitmod = 2 * 1+ (status.stat("iceResistance",0) * 2)
  elseif status.stat("iceResistance") <= 0.40 then
    self.icehitmod = 1 * 1+ (status.stat("iceResistance",0) * 1.5)    
  elseif status.stat("iceResistance") <= 0.30 then
    self.icehitmod = 0.6
  elseif status.stat("iceResistance") <= 0.10 then
    self.icehitmod = 0.2
  elseif status.stat("iceResistance") <= 0.05 then
    self.icehitmod = 0.05       
  end 
  self.icehitTimer = self.icehitmod +1
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

      -- environment checks
      daytime = daytimeCheck()
      underground = undergroundCheck()
      local lightLevel = getLight()
      
      self.biomeTimer = self.biomeTimer - dt 
      self.debuffApply = (self.baseDebuff* self.biomeTemp) * (-self.icehitmod) 
      self.damageApply = ( self.baseDmg * 1- math.min(status.stat("iceResistance"),0) ) * self.biomeTemp

      if self.biomeTimer <= 0 and status.stat("iceResistance") < 1.0 then


if status.stat("iceResistance") <= 0.75 then
  animator.setParticleEmitterOffsetRegion("smoke1", mcontroller.boundBox())
  animator.setParticleEmitterActive("smoke1", true) 
elseif status.stat("iceResistance") <= 0.50 then
  animator.setParticleEmitterOffsetRegion("smoke2", mcontroller.boundBox())
  animator.setParticleEmitterActive("smoke2", true) 
elseif status.stat("iceResistance") <= 0.25 then
  animator.setParticleEmitterOffsetRegion("smoke3", mcontroller.boundBox())
  animator.setParticleEmitterActive("smoke3", true) 
end

        -- are they in liquid?
        local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
        local mouthful = world.liquidAt(mouthposition)        
        if (world.liquidAt(mouthPosition)) then
		self.liquidMod = 1.50
		if self.timerRadioMessage == 0 then
		  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldwater", 1.0) -- send player a warning
		  self.timerRadioMessage = 60
		end
        else
          self.liquidMod = 1
        end

        -- is it nighttime or above ground? 
        if not daytime then
                self.nightPenalty = 1 + math.min(lightLevel,0)/100 
                if self.timerRadioMessage == 0 then
                  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomecoldnight", 1.0) -- send player a warning
                  self.timerRadioMessage = 60
		end
        else
          self.nightPenalty = 1
        end
        
        -- if it is above ground, exposure is worse
        
        -- first we check how windy it is
        self.windLevel =  world.windLevel(mcontroller.position())
        
        -- and if they are on the surface, we give them a penalty thanks to surface conditions
        if not underground then 
          self.situationalPenalty = (self.icehitmod) * (1+ (self.windLevel/100)) 
        else
          self.situationalPenalty = 0
        end 


        -- final Damage calculation
        self.damageApply = ( (self.damageApply) + (self.situationalPenalty) ) * ( (self.liquidMod) + (self.nightPenalty) )
        
         -- damage application per tick
          status.applySelfDamageRequest ({
            damageType = "IgnoresDef",
            damage = self.damageApply,
            damageSourceKind = "ice",
            sourceEntityId = entity.id()	
          })   
          
         -- being cold also consumes food faster to keep your body warm, but only below 70% protection
	 if status.isResource("food") and (status.stat("iceResistance",0) <= 0.7) then
	   status.modifyResource("food", (status.resource("food") * -0.01) )
	 end	          

          -- activate visuals and check stats
	  activateVisualEffects()
	  
	  -- set the timers
          self.biomeTimer = self.icehitTimer
          self.timerRadioMessage = self.timerRadioMessage - dt
          
      end 
      
      -- and finally, the colder you get the slower you move and the crappier your jump becomes
      -- this is outside of the timer, because it needs to always apply if you have less than 100% resist, not just onTick    
      if status.stat("iceResistance") < 0.9 then
             mcontroller.controlModifiers({
	         airJumpModifier = status.stat("iceResistance")+0.1, 
	         speedModifier = status.stat("iceResistance")+0.10 -- 0.01 is a failsafe so they are never at 0 speed
             })      
      end  

        --sb.logInfo("liquid mod "..self.liquidMod)
        --sb.logInfo("nightvalue "..self.nightPenalty)
        --sb.logInfo("situational "..self.situationalPenalty)
        --sb.logInfo("damage : "..self.damageApply)      
end       

function uninit()

end