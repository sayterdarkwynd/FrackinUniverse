function init()
  self.dead = false

  self.riseSpeed = config.getParameter("buzzing.riseSpeed")
  self.minGroundDistance = config.getParameter("buzzing.minGroundDistance")
  self.maxGroundDistance = config.getParameter("buzzing.maxGroundDistance")
  self.fallSpeed = config.getParameter("buzzing.fallSpeed")
  self.direction = {util.randomDirection(), 0}

  self.changeDirSpeed = config.getParameter("buzzing.changeDirSpeed")
  self.wanderDistance = config.getParameter("buzzing.wanderDistance")

  self.rotationDir = util.randomDirection()
  self.rotationSpeed = config.getParameter("buzzing.rotationSpeed")
  self.rotationChangeInterval = config.getParameter("buzzing.rotationChangeInterval")
  self.rotationTimer = self.rotationChangeInterval

  self.flySpeed = config.getParameter("buzzing.flySpeed")

  self.baseRotation = -math.pi / 4 --Head to the top right

  self.spawnPosition = mcontroller.position()
end

--------------------------------------------------------------------------------
function update(dt)
  local position = mcontroller.position()
  local minGroundLine = {position[1], position[2] - self.minGroundDistance}
  local maxGroundLine = {position[1], position[2] - self.maxGroundDistance}

  --If out of bounds, gently move in the other direction
  if world.lineTileCollision(position, minGroundLine, {"Null", "Block", "Dynamic"}) or world.liquidAt(minGroundLine) then
    self.direction[2] = self.direction[2] + self.riseSpeed * dt
  elseif not world.lineTileCollision(position, maxGroundLine, {"Null", "Block", "Dynamic"}) or not world.liquidAt(maxGroundLine) then
    self.direction[2] = self.direction[2] - self.fallSpeed * dt
  end

  if self.spawnPosition[1] - position[1] < -self.wanderDistance then
    self.direction[1] = self.direction[1] - self.changeDirSpeed * dt
  end

  if self.spawnPosition[1] - position[1] > self.wanderDistance then
    self.direction[1] = self.direction[1] + self.changeDirSpeed * dt
  end

  self.direction = vec2.norm(self.direction)

  --Rotate direction a bit to not fly in a straight line
  self.rotationTimer = self.rotationTimer - dt
  if self.rotationTimer < 0 then
    self.rotationDir = -self.rotationDir
    self.rotationTimer = self.rotationTimer + self.rotationChangeInterval
  end
  self.direction = vec2.rotate(self.direction, self.rotationDir * self.rotationSpeed * dt)

  mcontroller.controlFly(vec2.mul(self.direction, self.flySpeed))

  --Rotate the body to the direction it's flying
  local angle = math.atan(self.direction[2], math.abs(self.direction[1]))
  animator.rotateGroup("body", self.baseRotation + angle)
end

--------------------------------------------------------------------------------
function damage(args)
  if args.sourceKind == "bugnet" then
    status.setResourcePercentage("health", 0)
  end
end

--------------------------------------------------------------------------------
function shouldDie()
  return not status.resourcePositive("health") or self.dead
end
