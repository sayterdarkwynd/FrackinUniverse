require("/scripts/vec2.lua")
function init()

  self.timerRadioMessage = 0  -- initial delay for secondary radiomessages
    
  -- Environment Configuration --
  self.baseRate = config.getParameter("baseRate",0)                -- base Timer rate
  self.biomeTimer = config.getParameter("baseRate",0)
  self.biomeTimer2 = (self.baseRate * (1 + status.stat("iceResistance",0)) *2)
  
  self.biomeTemp = config.getParameter("biomeTemp",0)              -- sets the base variable for the biome/effect
  self.windLevel =  world.windLevel(mcontroller.position())        -- is there wind? we note that too
  self.baseDmg = config.getParameter("baseDmgPerTick",0)           -- damage per tick
  self.baseDebuff = config.getParameter("baseDebuffPerTick",0)     --debuff per tick
  self.biomeThreshold = config.getParameter("biomeThreshold",0)    -- base Modifier (tier)
  self.biomeNight = config.getParameter("biomeNight",0)            -- is this effect worse at night? how much?
  self.situationPenalty = config.getParameter("situationPenalty",0)-- situational modifiers are seldom applied...but provided if needed
  self.liquidPenalty = config.getParameter("liquidPenalty",0)      -- does liquid make things worse? how much?  
  -- activate visuals and check stats
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "biomeheat", 1.0) -- send player a warning
  activateVisualEffects()
  makeAlert()  
  
  script.setUpdateDelta(5)
end

function setEffectDamage()
  return ( ( self.baseDmg + self.situationPenalty + self.liquidPenalty + self.biomeNight ) *  (1 -status.stat("fireResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff + self.liquidPenalty + self.biomeNight ) * self.biomeTemp ) * (1 -status.stat("fireResistance",0) * self.biomeThreshold) )
end

function setEffectTime()
  return ( 1 - status.stat("fireResistance",0) * self.baseRate )
end

function setNightEffect()
  self.baseDmg = self.baseDmg + self.biomeNight
  self.baseDebuff = self.baseDebuff + self.biomeNight
  self.damageApply = setEffectDamage()
  self.debuffApply = setEffectDebuff() 
end

function setSituational()
  self.baseDmg = self.baseDmg + self.situationPenalty
  self.baseDebuff = self.baseDebuff + self.situationPenalty
  self.damageApply = setEffectDamage()
  self.debuffApply = setEffectDebuff() 
end

function setLiquidFactor()
  self.baseDmg = self.baseDmg + self.liquidPenalty
  self.baseDebuff = self.baseDebuff + self.liquidPenalty
  self.damageApply = setEffectDamage()
  self.debuffApply = setEffectDebuff()
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

-- alert the player that they are affected
function activateVisualEffects()
  effect.setParentDirectives("fade=ff7600=0.7")
  animator.setParticleEmitterOffsetRegion("firebreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("firebreath", true) 
end

function undergroundCheck()
  return world.underground(mcontroller.position()) 
end

function update(dt)
  self.damageApply = setEffectDamage()
  self.debuffApply = setEffectDebuff()
  self.baseRate = setEffectTime()
  
-- environment checks
underground = undergroundCheck()
  if underground then  
    world.sendEntityMessage(entity.id(), "queueRadioMessage", "ffbiomeheatcavern", 1.0) -- send player a warning
    self.timerRadioMessage = 1
  end  
       
  self.biomeTimer = self.biomeTimer - dt 

      if self.biomeTimer <= 0 and status.stat("fireResistance",0) < 1.0 then
	self.windLevel =  world.windLevel(mcontroller.position())

	if not underground then 
	  self.situationPenalty = config.getParameter("situationPenalty",0)
	else
	  self.situationPenalty = 1
	end 
          
	  activateVisualEffects()
	  makeAlert()

          self.biomeTimer = setEffectTime()
          self.timerRadioMessage = self.timerRadioMessage - dt  	  
      end 

      if status.stat("fireResistance",0) <=0.99 then      
	     self.damageApply = (self.damageApply /25) 
	     self.debuffApply = (self.debuffApply /100) 
	     
	     status.modifyResource("health", -self.damageApply * dt)
	   if status.isResource("food") then
	     if status.resource("food") >= 2 then
	       status.modifyResource("food", -self.debuffApply * dt )
	     end
           end  
             mcontroller.controlModifiers({
	         airJumpModifier = status.stat("fireResistance",0)+0.3, 
	         speedModifier = status.stat("fireResistance",0)+0.30 
             })              
      end  
      self.biomeTimer = self.biomeTimer - dt
      
end       


function makeAlert()
        world.spawnProjectile("fireinvis",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
        animator.playSound("bolt")
end

function uninit()

end