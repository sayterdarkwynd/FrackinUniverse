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

self.baseTemp = config.getParameter("baseTemp",0)
self.baseMod = config.getParameter("baseMod",0)
self.biomeMod = ( ( self.baseTemp ) * ( 1 +self.baseMod ) )

if (world.type() == "snow") then

elseif (world.type() == "arctic") then
self.baseTemp = config.getParameter("baseTemp",0)
elseif (world.type() == "icewaste") then
self.baseTemp = config.getParameter("baseTemp",0)
elseif (world.type() == "frozenvolcanic") then
self.baseTemp = config.getParameter("baseTemp",0)
elseif (world.type() == "icemoon") then
self.baseTemp = config.getParameter("baseTemp",0)
elseif (world.type() == "icewastedark") then
self.baseTemp = config.getParameter("baseTemp",0)
elseif (world.type() == "nitrogensea") then
self.baseTemp = config.getParameter("baseTemp",0)
elseif (world.type() == "nitrogenseafloor") then
self.baseTemp = config.getParameter("baseTemp",0)
elseif (world.type() == "arcticoceanfloor") then
self.baseTemp = config.getParameter("baseTemp",0)
end




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
  effect.setParentDirectives("fade=0022cc=0.8")
  local statusTextRegion = { 0, 1, 0, 1 }
  animator.setParticleEmitterOffsetRegion("statustext", statusTextRegion)
  animator.burstParticleEmitter("statustext")
  
  animator.setParticleEmitterOffsetRegion("icebreath", mcontroller.boundBox())
  animator.setParticleEmitterActive("icebreath", true) 
end

-- visual indicator for effect
function makeAlert()
        world.spawnProjectile("icesmoke",mcontroller.position(),entity.id(),directionTo,false,{power = 0,damageTeam = sourceDamageTeam})
        animator.playSound("bolt")
end


function update(dt)
    
      self.biomeTimer = self.biomeTimer - dt
      self.debuffApply = self.baseDebuff * (-self.icehitmod)
      self.damageApply = self.baseDmg * (self.icehitmod) 
      
      if self.biomeTimer <= 0 and status.stat("iceResistance") < 1.0 then
         -- damage application per tick
          status.applySelfDamageRequest ({
            damageType = "IgnoresDef",
            damage = self.damageApply,
            damageSourceKind = "ice",
            sourceEntityId = entity.id()	
          })   

          effect.addStatModifierGroup({
            {stat = "maxHealth", amount = self.debuffApply },
            {stat = "critChance", amount = 0 }
          })


  if status.stat("iceResistance") <= 0.99 then
    mcontroller.controlModifiers({
        speedModifier = 0.98
    }) 
  elseif status.stat("iceResistance") <= 0.80 then
    mcontroller.controlModifiers({
        speedModifier = 0.90
    })    
  elseif status.stat("iceResistance") <= 0.75 then
    mcontroller.controlModifiers({
        speedModifier = 0.80
    }) 
  elseif status.stat("iceResistance") <= 0.65 then
    mcontroller.controlModifiers({
        speedModifier = 0.70
    })  
  elseif status.stat("iceResistance") <= 0.50 then
    mcontroller.controlModifiers({
        speedModifier = 0.50
    }) 
  elseif status.stat("iceResistance") <= 0.40 then
    mcontroller.controlModifiers({
        speedModifier = 0.40
    })   
  elseif status.stat("iceResistance") <= 0.30 then
    mcontroller.controlModifiers({
        speedModifier = 0.30
    }) 
  elseif status.stat("iceResistance") <= 0.10 then
    mcontroller.controlModifiers({
        speedModifier = 0.20
    }) 
  elseif status.stat("iceResistance") <= 0.05 then
    mcontroller.controlModifiers({
        speedModifier = 0.15
    })     
  end 
  
  
          -- activate visuals and check stats
	  makeAlert()
	  activateVisualEffects()
	  
	  -- set the timer
          self.biomeTimer = self.icehitTimer

      end 	
end       

function uninit()

end