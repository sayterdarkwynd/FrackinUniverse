require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.controlMovement = config.getParameter("controlMovement")
  self.controlRotation = config.getParameter("controlRotation")
  self.rotationSpeed = 0
  self.timedActions = config.getParameter("timedActions", {})

  self.aimPosition = mcontroller.position()

  message.setHandler("updateProjectile", function(_, _, aimPosition)
      self.aimPosition = aimPosition
      return entity.id()
    end)

  message.setHandler("kill", function()
      projectile.die()
    end)
end

function update(dt)
  if self.aimPosition then
    if self.controlMovement then
      controlTo(self.aimPosition)
    end

    if self.controlRotation then
      rotateTo(self.aimPosition, dt)
    end

    for _, action in pairs(self.timedActions) do
      processTimedAction(action, dt)
    end
  end
end

function control(direction)
  mcontroller.approachVelocity(vec2.mul(vec2.norm(direction), self.controlMovement.maxSpeed), self.controlMovement.controlForce)
end

function controlTo(position)
  local offset = world.distance(position, mcontroller.position())
  mcontroller.approachVelocity(vec2.mul(vec2.norm(offset), self.controlMovement.maxSpeed), self.controlMovement.controlForce)
end

function rotateTo(position, dt)
  local vectorTo = world.distance(position, mcontroller.position())
  local angleTo = vec2.angle(vectorTo)
  if self.controlRotation.maxSpeed then
    local currentRotation = mcontroller.rotation()
    local angleDiff = util.angleDiff(currentRotation, angleTo)
    local diffSign = angleDiff > 0 and 1 or -1

    local targetSpeed = math.max(0.1, math.min(1, math.abs(angleDiff) / 0.5)) * self.controlRotation.maxSpeed
    local acceleration = diffSign * self.controlRotation.controlForce * dt
    self.rotationSpeed = math.max(-targetSpeed, math.min(targetSpeed, self.rotationSpeed + acceleration))
    self.rotationSpeed = self.rotationSpeed - self.rotationSpeed * self.controlRotation.friction * dt

    mcontroller.setRotation(currentRotation + self.rotationSpeed * dt)
  else
    mcontroller.setRotation(angleTo)
  end
end

function processTimedAction(action, dt)
  if not world.entityType() == "monster" then
	  if action.complete then
	    return
	  elseif action.delayTime then
	    action.delayTime = action.delayTime - dt
	    if action.delayTime <= 0 then
	      action.delayTime = nil
	    end
	  elseif action.loopTime then
	    action.loopTimer = action.loopTimer or 0
	    action.loopTimer = math.max(0, action.loopTimer - dt)
	    if action.loopTimer == 0 then
	      projectile.processAction(action)
	      action.loopTimer = action.loopTime
	      if action.loopTimeVariance then
		action.loopTimer = action.loopTimer + (2 * math.random() - 1) * action.loopTimeVariance
	      end
	    end
	  else
	    projectile.processAction(action)
	    action.complete = true
	  end
  end
end
