require "/scripts/vec2.lua"

function init()
  initCommonParameters()
end

function initCommonParameters()
  self.energyCost = config.getParameter("energyCostPerSecond")
  self.bombTimer = 0
end

function uninit()
  deactivate()
end


function checkStance()
    if self.pressDown then
      self.active2 = 1
      self.active3 = 0
      self.active4 = 0    
       animator.setParticleEmitterActive("shieldStance", false)
       animator.setParticleEmitterActive("powerStance", false)	    
       animator.setParticleEmitterActive("defenseStance", true)
       animator.playSound("activate")
    elseif self.pressUp then
      self.active2 = 0
      self.active3 = 1
      self.active4 = 0	     
       animator.setParticleEmitterActive("defenseStance", false)
       animator.setParticleEmitterActive("powerStance", false)	    
       animator.setParticleEmitterActive("shieldStance", true)
       animator.playSound("activate2")
    elseif self.pressJump then
      self.active2 = 0
      self.active3 = 0
      self.active4 = 1    
       animator.setParticleEmitterActive("defenseStance", false)
       animator.setParticleEmitterActive("shieldStance", false)	    
       animator.setParticleEmitterActive("powerStance", true)
       animator.playSound("activate3")
    end 
    --local configBombDrop = { power = 0 }
    --world.spawnProjectile("activeStance", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
    self.bombTimer = 3   
end

function update(args)
  if not self.specialLast and args.moves["special1"] then
    attemptActivation()
  end
  
  self.specialLast = args.moves["special1"]
  self.pressJump = args.moves["jump"]
  self.pressUp = args.moves["up"]
  self.pressDown = args.moves["down"]
  
  if not args.moves["special1"] then
    self.forceTimer = nil
  end


  if self.active2 == 1 then  -- in defense stance, we are slow
	      mcontroller.controlModifiers({
	        speedModifier = 0.75
	      })
  elseif self.active3 == 1 then -- in shield stance we are slightly slower
	      mcontroller.controlModifiers({
	        speedModifier = 0.90
	      })  
  elseif self.active4 == 1 then -- in attack stance we are faster
	      mcontroller.controlModifiers({
	        speedModifier = 1.1
	      })  
  end
  
  if self.active then
	    if self.bombTimer > 0 then
	      self.bombTimer = math.max(0, self.bombTimer - args.dt)
	    end

	    if self.pressDown or self.pressDown and self.active2== 1 then  --defense stance	    
	      status.setPersistentEffects("bugarmor", {
		{stat = "protection", effectiveMultiplier = 1.25},
		{stat = "powerMultiplier", effectiveMultiplier = 0.75},
		{stat = "maxEnergy", effectiveMultiplier = 0.75}
	      })
	      if self.bombTimer == 0 then
	        checkStance()
	      end
	    end
	    if self.pressUp or self.pressUp and self.active3== 1 then  -- shielding stance
	      status.setPersistentEffects("bugarmor", {
		{stat = "shieldBash", amount = 25},
		{stat = "shieldStaminaRegenBlock", effectiveMultiplier = 0.5},
		{stat = "perfectBlockLimit", effectiveMultiplier = 2},
		{stat = "shieldBashPush", amount = 5},
		{stat = "maxEnergy", effectiveMultiplier = 0.50}
	      })  
	      if self.bombTimer == 0 then
	        checkStance()
	      end	      
	    end
	    if self.pressJump or self.pressJump and self.active4== 1 then -- power stance	  
	      status.setPersistentEffects("bugarmor", {
		{stat = "protection", effectiveMultiplier = 0.75},
		{stat = "powerMultiplier", effectiveMultiplier = 1.25},
		{stat = "maxEnergy", effectiveMultiplier = 0.75}
	      })    
	      if self.bombTimer == 0 then
	        checkStance()
	      end	      
	    end      
    checkForceDeactivate(args.dt)
  end
end

function attemptActivation()
  if not self.active then
    activate()
    local configBombDrop = { power = 0 }
    world.spawnProjectile("activeStance", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)    
  elseif self.active then
      deactivate()
    if not self.forceTimer then
      self.forceTimer = 0
    end
  end
end

function checkForceDeactivate(dt)
  if self.forceTimer then
    self.forceTimer = self.forceTimer + dt
    if self.forceTimer >= self.forceDeactivateTime then
      deactivate()
      self.forceTimer = nil
      status.clearPersistentEffects("bugarmor")
      animator.setParticleEmitterActive("defenseStance", false)
      animator.setParticleEmitterActive("shieldStance", false)
      animator.setParticleEmitterActive("powerStance", false)        
    else
      attemptActivation()
    end
    return true
  else
    return false
  end
end

function activate()
  if not self.active then
        status.addEphemeralEffects{{effect = "foodcostarmor", duration = 900}}
	animator.setParticleEmitterActive("defenseStance", false)
	animator.setParticleEmitterActive("shieldStance", false)
	animator.setParticleEmitterActive("powerStance", false)    	
  else
        status.clearPersistentEffects("bugarmor")
	animator.setParticleEmitterActive("defenseStance", false)
	animator.setParticleEmitterActive("shieldStance", false)
	animator.setParticleEmitterActive("powerStance", false)        
        deactivate()
  end
  self.active = true
end

function deactivate()
  if self.active then
    status.removeEphemeralEffect("foodcostarmor")
    status.clearPersistentEffects("bugarmor")
    animator.setParticleEmitterActive("defenseStance", false)
    animator.setParticleEmitterActive("shieldStance", false)
    animator.setParticleEmitterActive("powerStance", false)    
  end
  self.active = false
end
