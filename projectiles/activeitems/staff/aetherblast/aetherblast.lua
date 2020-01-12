require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.delayTimer = config.getParameter("delayTime")

  self.controlRotation = config.getParameter("controlRotation")
  self.rotationSpeed = 0

  message.setHandler("updateProjectile", function(_, _, aimPosition)
    self.aimPosition = aimPosition
    return entity.id()
  end)

  message.setHandler("kill", function()
      projectile.die()
    end)
end

function update(dt)
  if self.delayTimer then
    if self.aimPosition then
      -- mcontroller.setRotation(vec2.angle(world.distance(self.aimPosition, mcontroller.position())))
      rotateTo(self.aimPosition, dt)
    end

    self.delayTimer = math.max(0, self.delayTimer - dt)
    if self.delayTimer == 0 then
      self.delayTimer = nil
      trigger()
    end
  end
end

function trigger()
  mcontroller.setVelocity(vec2.mul(vec2.norm(world.distance(self.aimPosition, mcontroller.position())), config.getParameter("triggerSpeed")))
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
