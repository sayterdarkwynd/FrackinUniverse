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
  self.biomeTimer2=  (self.baseRate * (1 + status.stat("poisonResistance",0)) *2)  --this second timer is for secondary effects (debuffs) and are much slower
  
  -- activate visuals and check stats
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "fubiomeproto", 1.0) -- send player a warning
  activateVisualEffects()

  script.setUpdateDelta(5)
end

function setEffectDamage()
  return ( ( self.baseDmg + self.situationPenalty + self.liquidPenalty + self.biomeNight ) *  (1 -status.stat("poisonResistance",0) ) * self.biomeThreshold  )
end

function setEffectDebuff()
  return ( ( ( self.baseDebuff + self.liquidPenalty + self.biomeNight ) * self.biomeTemp ) * (1 -status.stat("poisonResistance,0") * self.biomeThreshold) )
end

function setEffectTime()
  return (( self.biomeThreshold * self.baseRate ) * (1 + status.stat("poisonResistance,0")))
end


-- alert the player that they are affected
function activateVisualEffects()
  animator.setParticleEmitterOffsetRegion("coldbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("coldbreath", true) 
end

function activateVisualEffects2()
  effect.setParentDirectives("fade=306630=0.35")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
end

-- visual indicator for effect
function makeAlert()
        world.spawnProjectile("poisonsmoke",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
        animator.playSound("bolt")
end


function update(dt)
    
  self.damageApply = setEffectDamage()
  self.debuffApply = setEffectDebuff()
  self.baseRate = setEffectTime()     
  self.biomeTimer = self.biomeTimer - dt
  self.biomeTimer2 =  self.biomeTimer2 -dt
  
      if self.biomeTimer <= 0 and status.stat("poisonResistance",0) < 1.0 then
         -- damage application per tick
          status.applySelfDamageRequest ({
            damageType = "IgnoresDef",
            damage = self.damageApply,
            damageSourceKind = "poison",
            sourceEntityId = entity.id()	
          })   

          -- activate visuals and check stats
	  makeAlert()
	  activateVisualEffects()
	  
	  -- set the timer
          self.biomeTimer = self.baseRate
      end 
      if self.biomeTimer2 <= 0 and status.stat("poisonResistance",0) < 1.0 then      
          effect.addStatModifierGroup({
            {stat = "maxHealth", amount = -self.debuffApply },
            {stat = "critChance", amount = 0 }
          })
          activateVisualEffects2()
          self.biomeTimer2 = (self.biomeTimer * (1 + status.stat("poisonResistance",0))) * 2 
          sb.logInfo("timer : "..self.biomeTimer2)
      end    
          
end         

function uninit()

end