require "/scripts/vec2.lua"

function init()
  initCommonParameters()
  self.pressDown = false
  self.bombTimer = 0
end

function initCommonParameters()
  self.angularVelocity = 0
  self.angle = 0
  self.transformFadeTimer = 0

  self.energyCost = config.getParameter("energyCost")
  self.ballRadius = config.getParameter("ballRadius")
  self.ballFrames = config.getParameter("ballFrames")
  self.ballSpeed = config.getParameter("ballSpeed")
  self.transformFadeTime = config.getParameter("transformFadeTime", 0.3)
  self.transformedMovementParameters = config.getParameter("transformedMovementParameters")
  self.transformedMovementParameters.runSpeed = self.ballSpeed
  self.transformedMovementParameters.walkSpeed = self.ballSpeed
  self.basePoly = mcontroller.baseParameters().standingPoly
  self.collisionSet = {"Null", "Block", "Dynamic", "Slippery"}
  self.forceDeactivateTime = config.getParameter("forceDeactivateTime", 3.0)
  self.forceShakeMagnitude = config.getParameter("forceShakeMagnitude", 0.125)
end

function uninit()
  storePosition()
  deactivate()
end

function update(args)
  restoreStoredPosition()

   if not self.specialLast and args.moves["special1"] then
    attemptActivation()
  end
  self.specialLast = args.moves["special1"]
  self.pressDown = args.moves["down"]
  if not args.moves["special1"] then		  
    self.forceTimer = nil		
  end  
  
  if self.active then
    mcontroller.controlParameters(self.transformedMovementParameters)
    status.setResourcePercentage("energyRegenBlock", 1.0)

    updateAngularVelocity(args.dt)
    updateRotationFrame(args.dt)
    checkForceDeactivate(args.dt)

      if self.bombTimer > 0 then
        self.bombTimer = math.max(0, self.bombTimer - args.dt)
      end
    
    if self.pressDown and self.bombTimer == 0 then
      self.bombTimer = 1.6
      local configBombDrop = { power = 20 }
      animator.playSound("bombdrop")
      world.spawnProjectile("distortionbomb", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
    end
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function attemptActivation()
  if not self.active
      and not tech.parentLounging()
      and not status.statPositive("activeMovementAbilities")
      and status.overConsumeResource("energy", self.energyCost) then

    local pos = transformPosition()
    if pos then
      mcontroller.setPosition(pos)
      activate()
    end
  elseif self.active then
    local pos = restorePosition()
    if pos then
      mcontroller.setPosition(pos)
      deactivate()
	    elseif not self.forceTimer then		
      animator.playSound("forceDeactivate", -1)		
      self.forceTimer = 0		
    end		
  end		
end		
function checkForceDeactivate(dt)		
  animator.resetTransformationGroup("ball")		
  if self.forceTimer then		
    self.forceTimer = self.forceTimer + dt		
    mcontroller.controlModifiers({		
      movementSuppressed = true		
    })		
    local shake = vec2.mul(vec2.withAngle((math.random() * math.pi * 2), self.forceShakeMagnitude), self.forceTimer / self.forceDeactivateTime)		
    animator.translateTransformationGroup("ball", shake)		
    if self.forceTimer >= self.forceDeactivateTime then		
      deactivate()		
      self.forceTimer = nil
    else
      attemptActivation()
    end
    return true
  else
    animator.stopAllSounds("forceDeactivate")
    return false
  end
end

function storePosition()
  if self.active then
    storage.restorePosition = restorePosition()

    -- try to restore position. if techs are being switched, this will work and the storage will
    -- be cleared anyway. if the client's disconnecting, this won't work but the storage will remain to
    -- restore the position later in update()
    if storage.restorePosition then
      storage.lastActivePosition = mcontroller.position()
      mcontroller.setPosition(storage.restorePosition)
    end
  end
end

function restoreStoredPosition()
  if storage.restorePosition then
    -- restore position if the player was logged out (in the same planet/universe) with the tech active
    if vec2.mag(vec2.sub(mcontroller.position(), storage.lastActivePosition)) < 1 then
      mcontroller.setPosition(storage.restorePosition)
    end
    storage.lastActivePosition = nil
    storage.restorePosition = nil
  end
end

function updateAngularVelocity(dt)
  if mcontroller.groundMovement() then
    -- If we are on the ground, assume we are rolling without slipping to
    -- determine the angular velocity
    local positionDiff = world.distance(self.lastPosition or mcontroller.position(), mcontroller.position())
    self.angularVelocity = -vec2.mag(positionDiff) / dt / self.ballRadius

    if positionDiff[1] > 0 then
      self.angularVelocity = -self.angularVelocity
    end
  end
end

function updateRotationFrame(dt)
  self.angle = math.fmod(math.pi * 2 + self.angle + self.angularVelocity * dt, math.pi * 2)

  -- Rotation frames for the ball are given as one *half* rotation so two
  -- full cycles of each of the ball frames completes a total rotation.
  local rotationFrame = math.floor(self.angle / math.pi * self.ballFrames) % self.ballFrames
  animator.setGlobalTag("rotationFrame", rotationFrame)
end

function updateTransformFade(dt)
  if self.transformFadeTimer > 0 then
    self.transformFadeTimer = math.max(0, self.transformFadeTimer - dt)
    animator.setGlobalTag("ballDirectives", string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, self.transformFadeTimer / (self.transformFadeTime - 0.15))))
  elseif self.transformFadeTimer < 0 then
    self.transformFadeTimer = math.min(0, self.transformFadeTimer + dt)
    tech.setParentDirectives(string.format("?fade=FFFFFFFF;%.1f", math.min(1.0, -self.transformFadeTimer / (self.transformFadeTime - 0.15))))
  else
    animator.setGlobalTag("ballDirectives", "")
    tech.setParentDirectives()
  end
end

function positionOffset()
  return minY(self.transformedMovementParameters.collisionPoly) - minY(self.basePoly)
end

function transformPosition(pos)
  pos = pos or mcontroller.position()
  local groundPos = world.resolvePolyCollision(self.transformedMovementParameters.collisionPoly, {pos[1], pos[2] - positionOffset()}, 1, self.collisionSet)
  if groundPos then
    return groundPos
  else
    return world.resolvePolyCollision(self.transformedMovementParameters.collisionPoly, pos, 1, self.collisionSet)
  end
end

function restorePosition(pos)
  pos = pos or mcontroller.position()
  local groundPos = world.resolvePolyCollision(self.basePoly, {pos[1], pos[2] + positionOffset()}, 1, self.collisionSet)
  if groundPos then
    return groundPos
  else
    return world.resolvePolyCollision(self.basePoly, pos, 1, self.collisionSet)
  end
end

function activate()
  if not self.active then
    animator.burstParticleEmitter("activateParticles")
    animator.playSound("activate")
    animator.setAnimationState("ballState", "activate")
    self.angularVelocity = 0
    self.angle = 0
    self.transformFadeTimer = self.transformFadeTime
  end
  tech.setParentHidden(true)
  tech.setParentOffset({0, positionOffset()})
  tech.setToolUsageSuppressed(true)
  status.setPersistentEffects("movementAbility", {{stat = "activeMovementAbilities", amount = 1}})
  self.active = true
  status.setPersistentEffects("ballprotection", {{stat = "protection", amount = 5}})
  

 
end

function deactivate()
  if self.active then
    animator.burstParticleEmitter("deactivateParticles")
    animator.playSound("deactivate")
    animator.setAnimationState("ballState", "deactivate")
    self.transformFadeTimer = -self.transformFadeTime
  else
    animator.setAnimationState("ballState", "off")
  end
  animator.stopAllSounds("forceDeactivate")
  animator.setGlobalTag("ballDirectives", "")
  tech.setParentHidden(false)
  tech.setParentOffset({0, 0})
  tech.setToolUsageSuppressed(false)
  status.clearPersistentEffects("movementAbility")
  self.angle = 0
  self.active = false
  status.clearPersistentEffects("ballprotection")
end

function minY(poly)
  local lowest = 0
  for _,point in pairs(poly) do
    if point[2] < lowest then
      lowest = point[2]
    end
  end
  return lowest
end
