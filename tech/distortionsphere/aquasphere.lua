require "/tech/distortionsphere/distortionsphere.lua"

function init()
  initCommonParameters()
  self.ballLiquidSpeed = config.getParameter("ballLiquidSpeed")
  self.pressDown = false
  self.bombTimer = 0
end

function uninit()
  storePosition()
  deactivate()
  status.removeEphemeralEffect("swimboost2") --make sure it removes the swimboost it added earlier
  status.clearPersistentEffects("aquasphere")
end

function update(args)
  restoreStoredPosition()

  if not self.specialLast and args.moves["special1"] then
    attemptActivation()
  end
  self.specialLast = args.moves["special1"]
  self.pressDown = args.moves["primaryFire"]--attack button

  if not args.moves["special1"] then
    self.forceTimer = nil
  end

  if self.active then
    local inLiquid = mcontroller.liquidPercentage() >= 0.2   -- is above this amount of immersion

    ----------------------------------------------------
    -- if the player pushes Fire, they will drop a bomb
    ----------------------------------------------------
    if self.bombTimer > 0 then
      self.bombTimer = math.max(0, self.bombTimer - args.dt)
    end
    --projectile spawn----------------------------------
    if self.pressDown and self.bombTimer == 0 then
      self.bombTimer = 1.1
      local configBombDrop = { power = 2 }
      local configBombDrop2 = { power = 20 }
      animator.playSound("bombdrop")
      world.spawnProjectile("ngravityexplosion", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop)
      world.spawnProjectile("gravexplosion2", mcontroller.position(), entity.id(), {0, 0}, false, configBombDrop2)
    end
    ----------------------------------------------------

    if inLiquid then  -- if immersed in liquid do this
      status.setPersistentEffects("aquasphere", {{stat="breathProtection",amount=1}, {stat="waterbreathProtection",amount=1}})
      self.transformedMovementParameters.gravityMultiplier = -0.005 	-- upwards drag if idle
      if args.moves["up"] and args.moves["down"] then  			-- pushing both up and down cancels out momentum
        self.transformedMovementParameters.liquidForce = 0
        self.transformedMovementParameters.gravityMultiplier = 0
      end
      status.addEphemeralEffect("swimboost2") 				-- apply swim speed bonus
      self.transformedMovementParameters.runSpeed = self.ballLiquidSpeed  -- failsafes
      self.transformedMovementParameters.walkSpeed = self.ballLiquidSpeed -- failsafes
    else
      status.removeEphemeralEffect("swimboost2")
      status.clearPersistentEffects("aquasphere")
      self.transformedMovementParameters.gravityMultiplier = 1.5	-- reset to default gravity, juuuuust in case
      self.transformedMovementParameters.runSpeed = self.ballSpeed
      self.transformedMovementParameters.walkSpeed = self.ballSpeed
    end

    mcontroller.controlParameters(self.transformedMovementParameters)
    status.setResourcePercentage("energyRegenBlock", 1.0)

    local controlDirection = 0
    if args.moves["right"] then
      controlDirection = controlDirection - 1
      self.transformedMovementParameters.liquidForce = 100
    end
    if args.moves["left"] then
      controlDirection = controlDirection + 1
      self.transformedMovementParameters.liquidForce = 100
    end

    updateAngularVelocity(args.dt, inLiquid, controlDirection)
    updateRotationFrame(args.dt)
    checkForceDeactivate(args.dt)
  else
    status.removeEphemeralEffect("swimboost2") --make sure it removes the swimboost it added earlier
    status.clearPersistentEffects("aquasphere")
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function updateAngularVelocity(dt, inLiquid, controlDirection)
  if mcontroller.isColliding() then
    -- If we are on the ground, assume we are rolling without slipping to determine the angular velocity
    local positionDiff = world.distance(self.lastPosition or mcontroller.position(), mcontroller.position())
    self.angularVelocity = -vec2.mag(positionDiff) / dt / self.ballRadius

    if positionDiff[1] > 0 then
      self.angularVelocity = -self.angularVelocity
    end
  elseif inLiquid then
    if controlDirection ~= 0 then
      self.angularVelocity = 1.5 * self.ballLiquidSpeed * controlDirection
    else
      self.angularVelocity = self.angularVelocity - (self.angularVelocity * 0.8 * dt)
      if math.abs(self.angularVelocity) < 0.1 then
        self.angularVelocity = 0
      end
    end
  end
end
