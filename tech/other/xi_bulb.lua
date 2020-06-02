require "/scripts/vec2.lua"

function init()
  initCommonParameters()
end

function initCommonParameters()
  self.energyCost = config.getParameter("energyCostPerSecond")
  self.bombTimer = 0
  self.conshakTimer = 0
  self.xiBonus = status.stat("xiBonus")
end

function uninit()
  deactivate()
end

function getFood()
	if status.isResource("food") then
		self.foodValue = status.resource("food")
		self.energyValue = status.resource("energy")
	else
		self.foodValue = 50
		self.energyValue = status.resource("energy")
	end
end

function checkStance()
    if (self.conshakTimer < 350) then
    	animator.setParticleEmitterActive("bulb", false)
    else
      animator.playSound("xibulbActivate")
    end
    if self.pressDown then    
       animator.setParticleEmitterActive("bulbStance", true)
       animator.playSound("xibulbCharge")
    else
      animator.setParticleEmitterActive("bulbStance", false)
      status.clearPersistentEffects("bulbEffect") 
    end 
    self.bombTimer = 10  
end

function update(args)
  if not self.specialLast and args.moves["special1"] then
    attemptActivation()
    animator.playSound("activate")
  end
  
  self.specialLast = args.moves["special1"]
  self.pressDown = args.moves["down"]
  self.pressLeft = args.moves["left"]
  self.pressRight = args.moves["right"]
  self.pressUp = args.moves["up"]
  self.pressJump = args.moves["jump"]
  
  if not args.moves["special1"] then
    self.forceTimer = nil
  end

  -- make sure they are fed enough
  getFood()
  -- if fed, move to the effect
	  if self.active then
	    if self.bombTimer > 0 then
	      self.bombTimer = math.max(0, self.bombTimer - args.dt)
	    end
	    --make sure we are only holding down
	    if (self.pressDown) and not self.pressLeft and not self.pressRight and not self.pressUp and not self.pressJump then 
	      if (self.conshakTimer < 350) then
		self.conshakTimer = self.conshakTimer + 1  
		--set food to reduce, but never to 0
		if (self.foodValue >=10) then 
		  status.setResource("food",self.foodValue -0.05)  
		else
		  status.overConsumeResource("energy", config.getParameter("energyCostPerSecond"),1)
		  status.overConsumeResource("health", 0.035,1)
		end
	      else
		self.conshakTimer = 0
	      end

	      status.setPersistentEffects("bulbEffect", {})

	      animator.setParticleEmitterActive("bulbStance", true)
	      if self.bombTimer == 0 then
		checkStance()
	      end

	      if (self.conshakTimer >= 350) then
	      self.rand = math.random(1,3)  -- how many Bulbs can we potentially spawn?
	      self.onehundred = math.random(1,100)   --chance to spawn rarer bulb types
		      if (self.foodValue >=10) then    --must have sufficient food to grow a seed
			animator.setParticleEmitterActive("bulbStance", false)
			animator.setParticleEmitterActive("bulb", true)
			--world.placeObject("xi_bulb",mcontroller.position(),1) -- doesnt seem to work with that position
			if self.onehundred == 100 then
			  world.spawnItem("xi_bulb3", mcontroller.position(), 1)
			elseif self.onehundred > 80 then
			  world.spawnItem("xi_bulb2", mcontroller.position(), self.rand)
			else
			  world.spawnItem("xi_bulb", mcontroller.position(), self.rand)
			end
			local configBombDrop = { power = 0 }
			world.spawnProjectile("activeBulbCharged", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)    
			self.conshakTimer = 0
		      elseif (self.foodValue < 10) and self.energyValue > 20 then
			animator.setParticleEmitterActive("bulbStance", false)
			animator.setParticleEmitterActive("bulb", true)
			if self.onehundred == 100 then
			  world.spawnItem("xi_bulb3", mcontroller.position(), 1)
			elseif self.onehundred > 95 then
			  world.spawnItem("xi_bulb2", mcontroller.position(), self.rand)
			else
			  world.spawnItem("xi_bulb", mcontroller.position(), self.rand)
			end
			local configBombDrop = { power = 0 }
			world.spawnProjectile("activeBulbCharged", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)    
			self.conshakTimer = 0		      
		      end
	      end

	    else
	      animator.setParticleEmitterActive("bulbStance", false)
	      animator.setParticleEmitterActive("bulb", false)
	      status.clearPersistentEffects("bulbEffect")
	      self.conshakTimer = 0
	    end   

	    checkForceDeactivate(args.dt)
	  end  


end

function attemptActivation()
  if not self.active then
    activate()
    local configBombDrop = { power = 0 }
    world.spawnProjectile("activeBulb", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)    
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
      status.clearPersistentEffects("bulbEffect")   
      self.conshakTimer = 0
    else
      attemptActivation()
    end
    return true
  else
    return false
  end
end

function activate()
	status.clearPersistentEffects("bulbEffect")   
	self.active = true
end

function deactivate()
	if self.active then
	  status.clearPersistentEffects("bulbEffect")  
	end
	self.active = false
end
