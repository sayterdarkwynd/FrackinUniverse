--------------------------------------------------------------------------------
function init(args)
  self.sensors = sensors.create()

  self.minions = {}
  for i = 1, entity.configParameter("throwMaxMinions") do
    table.insert(self.minions, 0)
  end

  self.state = stateMachine.create({
    "moveState",
    "throwAttack",
    "shoutAttack"
  })
  self.state.enteringState = function(stateName)
    self.state.shuffleStates()
  end
  self.state.leavingState = function(stateName)
    entity.setAnimationState("movement", "idle")
  end

  entity.setAggressive(false)
  entity.setAnimationState("movement", "idle")
end

--------------------------------------------------------------------------------
function update(dt)
  self.position = mcontroller.position()

  if util.trackTarget(entity.configParameter("targetNoticeRadius")) then
    entity.setAggressive(true)
    self.state.pickState()
  elseif self.targetId == nil then
    entity.setAggressive(false)
  end

  self.state.update(dt)
  self.sensors.clear()
end

--------------------------------------------------------------------------------
function damage(args)
  if entity.health() > 0 then
    if args.sourceId ~= self.targetId then
      self.targetId = args.sourceId
      self.targetPosition = world.entityPosition(self.targetId)
      self.state.pickState()
    end
  end
end

--------------------------------------------------------------------------------
function move(direction)
  entity.setAnimationState("movement", "walk")
  mcontroller.controlMove(direction, true)
end

--------------------------------------------------------------------------------
function hasTarget()
  return self.targetId ~= nil
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  if hasTarget() then return nil end

  return {
    timer = entity.randomizeParameterRange("moveTimeRange"),
    direction = util.randomDirection()
  }
end

function moveState.update(dt, stateData)
  if self.sensors.blockedSensors.collision.any(true) then
    stateData.direction = -stateData.direction
  end

  move(stateData.direction)

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, entity.configParameter("moveCooldown")
  end

  return false
end

--------------------------------------------------------------------------------
throwAttack = {}

function throwAttack.enter()
  if not hasTarget() then return nil end

  for minionIndex, minionId in ipairs(self.minions) do
    if minionId == 0 or not world.entityExists(minionId) then
      return {
        minionIndex = minionIndex,
        timer = entity.configParameter("throwStartTime")
      }
    end
  end

  return nil
end

function throwAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, self.position)
  mcontroller.controlFace(toTarget[1])

  if world.magnitude(toTarget) > entity.configParameter("throwMaxDistance") then
    move(toTarget[1])
  else
    entity.setAnimationState("movement", "throw")

    stateData.timer = stateData.timer - dt

    if stateData.timer <= 0 then
      if stateData.thrown then
        return true, entity.configParameter("throwCooldown")
      else
        local entityId = world.spawnMonster("micropo", entity.toAbsolutePosition(entity.configParameter("throwSpawnOffset")))
        world.callScriptedEntity(entityId, "setSpawnDirection", mcontroller.facingDirection())
        self.minions[stateData.minionIndex] = entityId

        stateData.thrown = true
        stateData.timer = entity.configParameter("throwEndTime")
      end
    end
  end

  return false
end

--------------------------------------------------------------------------------
shoutAttack = {}

function shoutAttack.enter()
  if not hasTarget() then return nil end

  return {}
end

function shoutAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, self.position)
  mcontroller.controlFace(toTarget[1])

  if world.magnitude(toTarget) > entity.configParameter("shoutMaxDistance") then
    move(toTarget[1])

    return false
  else
    entity.setAnimationState("movement", "ranged")
    -- entity.setFireDirection(entity.configParameter("shoutProjectileOffset"), toTarget)

    local projectile = entity.animationStateProperty("movement", "projectile")
    if projectile ~= nil then
      -- entity.startFiring(projectile)
    else
      -- entity.stopFiring()
    end

    return entity.animationState("movement") == "idle"
  end
end
