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
 
  -- set values, activate effects
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeproto", 1.0) -- send player a warning
  activateVisualEffects()
  setValues()
  script.setUpdateDelta(5)
end

function setValues()
-- check resist level and apply modifier for effects
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

      -- light check
      daytime = daytimeCheck()
      underground = undergroundCheck()
      local lightLevel = getLight()
      
      self.biomeTimer = self.biomeTimer - dt 
      self.debuffApply = (self.baseDebuff* self.biomeTemp) * (-self.icehitmod) 
      self.damageApply = ( self.baseDmg * 1- math.min(status.stat("iceResistance"),0) ) * self.biomeTemp

      if self.biomeTimer <= 0 and status.stat("iceResistance") < 1.0 then
      
      -- Also handled here is the nasty effect being underwater in this temperature has upon you....
      -- are they in water? if so, they ain't gonna like it
        local mouthPosition = vec2.add(mcontroller.position(), status.statusProperty("mouthPosition"))
        local mouthful = world.liquidAt(mouthposition)
	if (world.liquidAt(mouthPosition)) and (inWater == 0) and (mcontroller.liquidId()== 1) or (mcontroller.liquidId()== 6) or (mcontroller.liquidId()== 58) or (mcontroller.liquidId()== 12) then
            status.modifyResource("food", (status.resource("food") * -0.005) )
            self.damageApply = self.damageApply * 1.75
	    inWater = 1
	else
	  isDry()
        end   
        
        -- is it nighttime or above ground? if so, its colder
        if not daytime then
          self.damageApply = self.damageApply * 2 - math.min(lightLevel,0)  
          if (world.liquidAt(mouthPosition)) and (inWater == 0) and (mcontroller.liquidId()== 1) or (mcontroller.liquidId()== 6) or (mcontroller.liquidId()== 58) or (mcontroller.liquidId()== 12) then
             status.modifyResource("food", (status.resource("food") * -0.005) )
            self.damageApply = self.damageApply * 1.75
	    inWater = 1
	  else
	    isDry()
          end            
        end
        -- if it is above ground, exposure is worse
          if not underground then 
            self.damageApply = self.damageApply + (self.icehitmod *1.5)
          end 

         -- damage application per tick
          status.applySelfDamageRequest ({
            damageType = "IgnoresDef",
            damage = self.damageApply,
            damageSourceKind = "ice",
            sourceEntityId = entity.id()	
          })   
          
         -- being cold also consumes food faster to keep your body warm
	 if status.isResource("food") then
	  status.modifyResource("food", (status.resource("food") * -0.01) )
	 end	          

          -- activate visuals and check stats
	  activateVisualEffects()
	  
	  -- set the timer
          self.biomeTimer = self.icehitTimer
          
      end 
      
      -- and finally, the colder you get the slower you move and the crappier your jump becomes
      -- this is outside of the timer, because it needs to always apply if you have less than 100% resist, not just onTick    
      if status.stat("iceResistance") < 0.9 then
             mcontroller.controlModifiers({
	         airJumpModifier = status.stat("iceResistance")+0.1, 
	         speedModifier = status.stat("iceResistance")+0.10 -- 0.01 is a failsafe so they are never at 0 speed
             })      
      end  
      
end       

function uninit()

end