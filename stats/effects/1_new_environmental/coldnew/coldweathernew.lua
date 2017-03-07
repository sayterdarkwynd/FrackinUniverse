function init()
  -- Environment Configuration --
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

-- visual indicator for effect
function makeAlert()
        world.spawnProjectile("settlingsnow",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
        animator.playSound("bolt")
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

function update(dt)

      -- det defaults
      daytime = daytimeCheck()
      underground = undergroundCheck()
      local lightLevel = getLight()
      
      self.biomeTimer = self.biomeTimer - dt
      self.debuffApply = self.baseDebuff * (-self.icehitmod)
      self.damageApply = ( self.baseDmg * 1- math.min(status.stat("iceResistance"),0) )

      if self.biomeTimer <= 0 and status.stat("iceResistance") < 1.0 then
        -- is it nighttime or above ground? if so, its colder
        if not daytime then
          self.damageApply = self.damageApply * 1 - math.min(lightLevel,0)   
        end
        -- if it is above ground, exposure is worse
          if not underground then 
            self.damageApply = self.damageApply + (self.icehitmod *2.5)
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
	 
	 -- and finally, the colder you get the slower you move and the crappier your jump becomes
             mcontroller.controlModifiers({
	         airJumpModifier = status.stat("iceResistance"),
	         speedModifier = status.stat("iceResistance")
             })

          
          -- activate visuals and check stats
	  makeAlert()
	  activateVisualEffects()
	  
	  -- set the timer
          self.biomeTimer = self.icehitTimer

      end 	
end       

function uninit()

end