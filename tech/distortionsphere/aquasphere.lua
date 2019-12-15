require "/tech/distortionsphere/distortionsphere.lua"

function init()
  initCommonParameters()

  self.ballLiquidSpeed = config.getParameter("ballLiquidSpeed")
end

function update(args)
  restoreStoredPosition()

  if not self.specialLast and args.moves["special1"] then
    attemptActivation()
  end
  self.specialLast = args.moves["special1"]
  self.up = args.moves["up"]
  
  if not args.moves["special1"] then
    self.forceTimer = nil
  end
	  
  if self.active then
    local inLiquid = mcontroller.liquidPercentage() > 0.2

    if inLiquid then
  	  if args.moves["up"] then
	    self.transformedMovementParameters.gravityMultiplier = -0.05 --pushing up launches us upwards when in water
	    sb.logInfo(self.transformedMovementParameters.gravityMultiplier)
	  end  
      self.transformedMovementParameters.runSpeed = self.ballLiquidSpeed
      self.transformedMovementParameters.walkSpeed = self.ballLiquidSpeed
    else
      self.transformedMovementParameters.gravityMultiplier = 1.5
      self.transformedMovementParameters.runSpeed = self.ballSpeed
      self.transformedMovementParameters.walkSpeed = self.ballSpeed
    end

    mcontroller.controlParameters(self.transformedMovementParameters)
    status.setResourcePercentage("energyRegenBlock", 1.0)

    local controlDirection = 0
    if args.moves["right"] then controlDirection = controlDirection - 1 end
    if args.moves["left"] then controlDirection = controlDirection + 1 end

    updateAngularVelocity(args.dt, inLiquid, controlDirection)
    updateRotationFrame(args.dt)

    checkForceDeactivate(args.dt)
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
end

function updateAngularVelocity(dt, inLiquid, controlDirection)
  if mcontroller.isColliding() then
    -- If we are on the ground, assume we are rolling without slipping to
    -- determine the angular velocity
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
