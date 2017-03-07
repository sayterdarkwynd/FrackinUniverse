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
  if status.stat("poisonResistance") <= 0.99 then
    self.poisonhitmod = 2 * 1+ (status.stat("poisonResistance",0) * 4)
  elseif status.stat("poisonResistance") <= 0.80 then
    self.poisonhitmod = 2 * 1+ (status.stat("poisonResistance",0) * 3.5)    
  elseif status.stat("poisonResistance") <= 0.75 then
    self.poisonhitmod = 2 * 1+ (status.stat("poisonResistance",0) * 3) 
  elseif status.stat("poisonResistance") <= 0.65 then
    self.poisonhitmod = 2 * 1+ (status.stat("poisonResistance",0) * 2.5)    
  elseif status.stat("poisonResistance") <= 0.50 then
    self.poisonhitmod = 2 * 1+ (status.stat("poisonResistance",0) * 2)
  elseif status.stat("poisonResistance") <= 0.40 then
    self.poisonhitmod = 1 * 1+ (status.stat("poisonResistance",0) * 1.5)    
  elseif status.stat("poisonResistance") <= 0.30 then
    self.poisonhitmod = 0.6
  elseif status.stat("poisonResistance") <= 0.10 then
    self.poisonhitmod = 0.2
  elseif status.stat("poisonResistance") <= 0.05 then
    self.poisonhitmod = 0.05       
  end 
  
  self.poisonhitTimer = self.poisonhitmod +1
end

-- alert the player that they are affected
function activateVisualEffects()
  effect.setParentDirectives("fade=306630=0.8")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  
  animator.setParticleEmitterOffsetRegion("coldbreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("coldbreath", true) 
end

-- visual indicator for effect
function makeAlert()
        world.spawnProjectile("poisonsmoke",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
        animator.playSound("bolt")
end


function update(dt)
    
      self.biomeTimer = self.biomeTimer - dt
      self.debuffApply = self.baseDebuff * (-self.poisonhitmod)
      self.damageApply = self.baseDmg * (-self.poisonhitmod) 
      
      if self.biomeTimer <= 0 and status.stat("poisonResistance") < 1.0 then
         -- damage application per tick
          status.applySelfDamageRequest ({
            damageType = "IgnoresDef",
            damage = self.damageApply,
            damageSourceKind = "poison",
            sourceEntityId = entity.id()	
          })   

          effect.addStatModifierGroup({
            {stat = "maxHealth", amount = self.debuffApply },
            {stat = "critChance", amount = 0 }
          })
          
          -- activate visuals and check stats
	  makeAlert()
	  activateVisualEffects()
	  
	  -- set the timer
          self.biomeTimer = self.poisonhitTimer

      end 	
end       

function uninit()

end