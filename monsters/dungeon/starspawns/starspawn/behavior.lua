--------------------------------------------------------------------------------
function init()
  self.sensors = sensors.create()

  capturepod.onInit()

  self.state = stateMachine.create({
    "attackState",
    "moveState",
    "captiveState"
  })
  self.state.leavingState = function(stateName)
    animator.setAnimationState("movement", "idle")
  end

  self.jumpHoldTime = 0

  monster.setAggressive(true)
  monster.setDamageOnTouch(true)
  monster.setDeathParticleBurst("deathPoof")
  animator.setAnimationState("movement", "idle")
end

--------------------------------------------------------------------------------
function update(dt)
  util.trackTarget(config.getParameter("noticeDistance"))
  if self.targetId ~= nil and not attacking() then
    self.state.pickState(self.targetId)
  end

  self.state.update(dt)
  self.sensors.clear()

  -- Update animation
  if mcontroller.onGround() then
    animator.setAnimationState("movement", "idle")
  else
    local velocity = mcontroller.velocity()

    if velocity[2] < 0 then
      animator.setAnimationState("movement", "fall")
    else
      animator.setAnimationState("movement", "jump")
    end
  end
end

--------------------------------------------------------------------------------
function damage(args)
  capturepod.onDamage(args)
end

--------------------------------------------------------------------------------
function shouldDie()
  return self.dead or status.resource("health") <= 0
end

--------------------------------------------------------------------------------
function die()
  if not capturepod.onDie() then
    local size = config.getParameter("poSize")

    if size == "medium" then
      local entityId = world.spawnMonster("microslime", monster.toAbsolutePosition({ -1, 4 }), { level = monster.level() })
      world.callScriptedEntity(entityId, "setSpawnDirection", -1)

      entityId = world.spawnMonster("microslime", monster.toAbsolutePosition({ 1, 4 }), { level = monster.level() })
      world.callScriptedEntity(entityId, "setSpawnDirection", 1)
    elseif size == "large" then
      local entityId = world.spawnMonster("microslime", monster.toAbsolutePosition({ -1, 3 }), { level = monster.level() })
      world.callScriptedEntity(entityId, "setSpawnDirection", -1)

      entityId = world.spawnMonster("microslime", monster.toAbsolutePosition({ 1, 3 }), { level = monster.level() })
      world.callScriptedEntity(entityId, "setSpawnDirection", 1)
    end
  end
end

--------------------------------------------------------------------------------
function setSpawnDirection(direction)
  local spawnVelocity = config.getParameter("spawnVelocity")
  mcontroller.setVelocity({ spawnVelocity[1] * direction, spawnVelocity[2] })
end

--------------------------------------------------------------------------------
function poSize()
  return config.getParameter("poSize")
end

--------------------------------------------------------------------------------
function attacking()
  return self.state.stateDesc() == "attackState"
end

--------------------------------------------------------------------------------
function move(delta, run)
  if self.jumpHoldTime > 0 then
    mcontroller.controlHoldJump()
    self.jumpHoldTime = self.jumpHoldTime - script.updateDt()
  else
    script.setUpdateDelta(5)
  end

  if mcontroller.onGround() then
    if delta[2] < 0 and not onSolidGround() then
      mcontroller.controlDown()
      return
    end
    mcontroller.controlJump()

    if delta[2] > config.getParameter("largeJumpYThreshold") then
      self.jumpHoldTime = config.getParameter("largeHumpHoldTime")
    else
      self.jumpHoldTime = config.getParameter("smallBounceHoldTime")
    end
    script.setUpdateDelta(1)
  end

  mcontroller.controlMove(delta[1], true)
end

--Check if entity is on solid ground (not platforms)
function onSolidGround()
  local position = mcontroller.position()
  local bounds = boundingBox()

  local groundRegion = {
    position[1] + bounds[1] - 0.05, position[2] + bounds[2] - 0.95,
    position[1] + bounds[3] + 0.05, position[2] + bounds[2] + 0.05
  }
  return world.rectTileCollision(groundRegion, "Dynamic")
end

--------------------------------------------------------------------------------
function boundingBox(force)
  if self.boundingBox and not force then return self.boundingBox end

  local collisionPoly = mcontroller.collisionPoly()
  local bounds = {0, 0, 0, 0}

  for _,point in pairs(collisionPoly) do
    if point[1] < bounds[1] then bounds[1] = point[1] end
    if point[2] < bounds[2] then bounds[2] = point[2] end
    if point[1] > bounds[3] then bounds[3] = point[1] end
    if point[2] > bounds[4] then bounds[4] = point[2] end
  end
  self.boundingBox = bounds

  return bounds
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  if capturepod.isCaptive() then return nil end

  return {
    timer = util.randomInRange(config.getParameter("moveTimeRange")),
    direction = util.toDirection(math.random(100) - 50)
  }
end

function moveState.update(dt, stateData)
  if self.sensors.blockedSensors.collision.any(true) then
    stateData.direction = -stateData.direction
  end

  move({ stateData.direction, 0 }, false)

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, util.randomInRange(config.getParameter("moveCooldownTimeRange"))
  end

  return false
end

--------------------------------------------------------------------------------
attackState = {}

function attackState.enterWith(targetId)
  return { timer = 0 }
end

function attackState.update(dt, stateData)
  if self.targetPosition == nil then return true end

  if self.targetId == nil then
    stateData.timer = stateData.timer + dt
    if stateData.timer > config.getParameter("attackSearchTime") then
      return true
    end
  end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  move(toTarget, dt, true)

  return false
end

--------------------------------------------------------------------------------
captiveState = {
  closeDistance = 4,
  runDistance = 12,
}

function captiveState.enter()
  if not capturepod.isCaptive() or self.targetId ~= nil then return nil end

  return { running = false }
end

function captiveState.update(dt, stateData)
  -- Translate owner uuid to entity id
  if self.ownerEntityId ~= nil then
    if not world.entityExists(self.ownerEntityId) then
      self.ownerEntityId = nil
    end
  end

  if self.ownerEntityId == nil then
    local playerIds = world.entityQuery(mcontroller.position(), 50, {includedTypes = {"player"}})
    for _, playerId in pairs(playerIds) do
      if world.entityUuid(playerId) == storage.ownerUuid then
        self.ownerEntityId = playerId
        break
      end
    end
  end

  -- Owner is nowhere around
  if self.ownerEntityId == nil then
    return false
  end

  local ownerPosition = world.entityPosition(self.ownerEntityId)
  local toOwner = world.distance(ownerPosition, mcontroller.position())
  local distance = math.abs(toOwner[1])

  local movement
  if distance < captiveState.closeDistance then
    stateData.running = false
    movement = 0
  elseif toOwner[1] < 0 then
    movement = -1
  elseif toOwner[1] > 0 then
    movement = 1
  end

  if distance > captiveState.runDistance then
    stateData.running = true
  end

  move({ movement, toOwner[2] }, stateData.running)

  return false
end
