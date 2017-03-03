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

  -- lasers
  self.projectileType = config.getParameter("projectileType")
  self.projectileParameters = config.getParameter("projectileParameters", {})
  self.projectileParameters.power = config.getParameter("power")
  self.projectileParameters.powerMultiplier = projectile.powerMultiplier()

  self.spawnTime = config.getParameter("spawnRate")
  self.spawnTimer = self.spawnTime
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

  self.spawnTimer = math.max(0, self.spawnTimer - dt)
  if self.spawnTimer == 0 then
    createProjectile()
    self.spawnTimer = self.spawnTime
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

function createProjectile()
  local angle = mcontroller.rotation()
  local aimVec = vec2.withAngle(angle)
  local position = vec2.add(mcontroller.position(), vec2.rotate({4,0},angle))
  world.spawnProjectile(
      self.projectileType,
      position,
      projectile.sourceEntity(),
      aimVec,
      false,
      self.projectileParameters
    )
end
