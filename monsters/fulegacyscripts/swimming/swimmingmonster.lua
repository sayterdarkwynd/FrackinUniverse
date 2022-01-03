function init()
  local scripts = config.getParameter("scripts")
  local states = stateMachine.scanScripts(scripts, "(%a+State)%.lua")
  self.state = stateMachine.create(states)

  self.aggressive = config.getParameter("aggressive", false)

  self.target = false
  self.targetChangeTimer = 0
  self.targetHoldTimer = 0

  self.moveRatioLimit = config.getParameter("moveRatioLimit", false)
  self.directionChangeTimer = 0
  self.slowSpeed = mcontroller.baseParameters().flySpeed / 2.0

  self.rotation = 0
  animator.setAnimationState("movement", "swimSlow")

  monster.setDeathSound("deathPuff")
  monster.setDeathParticleBurst(config.getParameter("deathParticles"))

  script.setUpdateDelta(10)
end

function damage(args)
  if self.targetChangeTimer <= 0 and args.sourceId ~= self.target and args.sourceId ~= 0 then
    if not self.target then
      self.state.endState()
    end
    setTarget(args.sourceId)
  end
end

function findTarget()
  local targetId = util.closestValidTarget(config.getParameter("targetSearchRadius"))
  if targetValid(targetId) then setTarget(targetId) end
end

function targetValid(targetId)
  return
    entity.isValidTarget(targetId) and
    world.liquidAt(world.entityPosition(targetId)) and
    vec2.mag(entity.distanceToEntity(targetId)) <= config.getParameter("targetHoldRadius")
end

function setTarget(targetId)
  if targetId and targetId ~= 0 and self.targetChangeTimer <= 0 then
    self.target = targetId
    self.targetChangeTimer = config.getParameter("targetChangeCooldown")
  else
    self.target = false
    self.targetChangeTimer = 0
  end
end

function updateTarget()
  if self.target and not world.entityExists(self.target) then
    self.target = false
    self.aggressive = config.getParameter("aggressive", false)
  end

  if not self.target and self.aggressive then
    findTarget()
  end
end

function update(dt)
  if not mcontroller.liquidMovement() then
    if self.state.stateDesc() ~= "flopState" then
      self.state.pickState({flop = true})
    end
  else
    updateTarget()

    if self.target then
      script.setUpdateDelta(2)

      if self.state.stateDesc() ~= "fleeState" and not targetValid(self.target) then
        self.state.pickState({flee = true})
      end
    else
      script.setUpdateDelta(10)
    end

    if not self.state.hasState() then
      self.state.pickState()
    end
  end

  self.state.update(dt)

  if self.directionChangeTimer > 0 then self.directionChangeTimer = self.directionChangeTimer - dt end
end

function move(direction, run, noRatioLimit)
  moveDirection = {direction[1], direction[2]}
  if not noRatioLimit and self.moveRatioLimit and moveDirection[1] ~= 0 then
    -- limit movement angle
    if math.abs(moveDirection[2] / moveDirection[1]) > self.moveRatioLimit then
      moveDirection[2] = math.abs(moveDirection[1] * self.moveRatioLimit) * util.toDirection(moveDirection[2])
    end
  end

  moveDirection = vec2.norm(moveDirection)

  -- don't change direction too often
  if util.toDirection(moveDirection[1]) ~= util.toDirection(mcontroller.facingDirection()) then
    if self.directionChangeTimer > 0 then
      moveDirection[1] = -moveDirection[1]
    else
      self.directionChangeTimer = config.getParameter("directionChangeCooldown")
    end
  end

  -- calculate rotation
  setBodyDirection(moveDirection)

  -- move
  if run ~= false then
    mcontroller.controlFly(vec2.mul({ moveDirection[1], moveDirection[2] }, 1000))
    animator.setAnimationState("movement", "swimFast")
  else
    mcontroller.controlFly(vec2.mul({ moveDirection[1], moveDirection[2] }, self.slowSpeed))
    animator.setAnimationState("movement", "swimSlow")
  end
end

function collides(sensorGroup, direction)
  for _, sensor in ipairs(config.getParameter(sensorGroup)) do
    -- world.debugPoint(monster.toAbsolutePosition(vec2.rotate(sensor, self.rotation)), "blue")
    if world.pointTileCollision(monster.toAbsolutePosition(vec2.rotate(sensor, self.rotation)), {"Dynamic", "Null", "Block"}) then
      return true
    end
  end

  return false
end

function setBodyDirection(direction)
  if direction[2] ~= 0 then
    local rotateAmount = math.atan(direction[2], direction[1])
    if rotateAmount < 0 then rotateAmount = rotateAmount + 2 * math.pi end
    if direction[1] < 0 then rotateAmount = math.pi - rotateAmount end

    self.rotation = rotateAmount
  else
    self.rotation = 0
  end
  animator.rotateGroup("all", self.rotation)
  mcontroller.setRotation(mcontroller.facingDirection() > 0 and self.rotation or -self.rotation)
end
