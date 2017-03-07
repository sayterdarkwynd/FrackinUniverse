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
  self.radioMessageTimer = 1
  self.baseDmg = config.getParameter("baseDmgPerTick",0)
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)
  self.baseRate = config.getParameter("baseRate",0)
  self.biomeTimer = config.getParameter("baseRate",0)
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeheat", 1.0) -- send player a warning
  -- set values, activate effects
  activateVisualEffects()
  setValues()
  self.timerRadioMessage = 0
  self.situationalPenalty = 0
  script.setUpdateDelta(5)
end

function setValues()
-- check resist level and apply modifier for effects
-- this effects how hard the environmental effects hit you in general. Note that the higher up you go in resists, the less severe effects become , until they are effectively ignorable.
  if status.stat("radioactiveResistance") <= 0.99 then
    self.radioactivehitmod = 1.5 * 1+ (status.stat("radioactiveResistance",0) * 4)
  elseif status.stat("radioactiveResistance") <= 0.80 then
    self.radioactivehitmod = 1.25 * 1+ (status.stat("radioactiveResistance",0) * 3.5)    
  elseif status.stat("radioactiveResistance") <= 0.75 then
    self.radioactivehitmod = 1 * 1+ (status.stat("radioactiveResistance",0) * 3) 
  elseif status.stat("radioactiveResistance") <= 0.65 then
    self.radioactivehitmod = 0.8 * 1+ (status.stat("radioactiveResistance",0) * 2.5)    
  elseif status.stat("radioactiveResistance") <= 0.50 then
    self.radioactivehitmod = 0.6 * 1+ (status.stat("radioactiveResistance",0) * 2)
  elseif status.stat("radioactiveResistance") <= 0.40 then
    self.radioactivehitmod = 0.4 * 1+ (status.stat("radioactiveResistance",0) * 1.5)    
  elseif status.stat("radioactiveResistance") <= 0.30 then
    self.radioactivehitmod = 0.1
  elseif status.stat("radioactiveResistance") <= 0.10 then
    self.radioactivehitmod = 0.05
  elseif status.stat("radioactiveResistance") <= 0.05 then
    self.radioactivehitmod = 0.05       
  else
    self.radioactivehitmod = 0.05
  end 
    self.firehitTimer = self.radioactivehitmod
end

-- alert the player that they are affected
function activateVisualEffects()
  effect.setParentDirectives("fade=33dd15=0.7")
  animator.setParticleEmitterOffsetRegion("radioactivebreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("radioactivebreath", true) 
end


function undergroundCheck()
	return world.underground(mcontroller.position()) 
end


function update(dt)


-- environment checks
underground = undergroundCheck()
  if underground then  
    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeheatcavern", 1.0) -- send player a warning
    self.timerRadioMessage = 1
  end  
  
self.biomeTimer = self.biomeTimer - dt 
self.debuffApply = (self.baseDebuff* self.biomeTemp) * (-self.radioactivehitmod) 
self.damageApply = ( self.baseDmg * 1- math.min(status.stat("radioactiveResistance"),0) ) * self.biomeTemp

-- if timer is 0 and they have less than 100% resist, proceed
      if self.biomeTimer <= 0 and status.stat("radioactiveResistance") < 1.0 then

          effect.addStatModifierGroup({
            {stat = "maxHealth", amount = self.debuffApply },
            {stat = "maxEnergy", amount = self.debuffApply * 2 }
          })
	 
	-- and if they are on the surface, we give them a penalty thanks to surface conditions
	if not underground then 
	  self.situationalPenalty = (self.radioactivehitmod) * (2+ (self.windLevel/100))
	else
	  self.situationalPenalty = 0
	end 
	   -- final Damage calculation
	   -- apply the damage constantly but silently         
	   self.damageApply = ( (self.damageApply) + (self.situationalPenalty) ) * ( 1+(self.biomeTemp))
	   status.modifyResource("health", (-self.damageApply * (1-status.stat("radioactiveResistance"))*self.biomeTemp ) * dt)
	   status.modifyResource("food", (-self.damageApply * (1-status.stat("radioactiveResistance")/10)) * dt)
	   
        -- they look as if aflame
        world.spawnProjectile("fireinvis",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
 	 
          -- activate visuals and check stats
	  activateVisualEffects()
	  -- set the timers
          self.biomeTimer = self.firehitTimer/2
          self.timerRadioMessage = self.timerRadioMessage - dt  	  
      end 
      
      -- and finally, the hotter you get the slower you move and the crappier your jump becomes
      -- this is outside of the timer, because it needs to always apply if you have less than 100% resist, not just onTick    
      if status.stat("radioactiveResistance") < 0.9 then
             mcontroller.controlModifiers({
	         airJumpModifier = status.stat("radioactiveResistance")+0.3, 
	         speedModifier = status.stat("radioactiveResistance")+0.30 
             })      
      end  
 
end       

function uninit()

end