--------------------------------------------------------------------------------
function init(args)
  self.sensors = sensors.create()

  self.minions = {}
  for i = 1, config.getParameter("throwMaxMinions") do
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
    animator.setAnimationState("movement", "idle")
  end

  monster.setAggressive(false)
  animator.setAnimationState("movement", "idle")
end

--------------------------------------------------------------------------------
function update(dt)
  self.position = mcontroller.position()

  if util.trackTarget(config.getParameter("targetNoticeRadius")) then
    monster.setAggressive(true)
    self.state.pickState()
  elseif self.targetId == nil then
    monster.setAggressive(false)
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
  animator.setAnimationState("movement", "walk")
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
    return true, config.getParameter("moveCooldown")
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
        timer = config.getParameter("throwStartTime")
      }
    end
  end

  return nil
end

function throwAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, self.position)
  mcontroller.controlFace(toTarget[1])

  if world.magnitude(toTarget) > config.getParameter("throwMaxDistance") then
    move(toTarget[1])
  else
    animator.setAnimationState("movement", "throw")

    stateData.timer = stateData.timer - dt

    if stateData.timer <= 0 then
      if stateData.thrown then
        return true, config.getParameter("throwCooldown")
      else
        local entityId = world.spawnMonster("micropo", monster.toAbsolutePosition(config.getParameter("throwSpawnOffset")))
        world.callScriptedEntity(entityId, "setSpawnDirection", mcontroller.facingDirection())
        self.minions[stateData.minionIndex] = entityId

        stateData.thrown = true
        stateData.timer = config.getParameter("throwEndTime")
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

  if world.magnitude(toTarget) > config.getParameter("shoutMaxDistance") then
    move(toTarget[1])

    return false
  else
    animator.setAnimationState("movement", "ranged")
    -- entity.setFireDirection(config.getParameter("shoutProjectileOffset"), toTarget)

    local projectile = entity.animationStateProperty("movement", "projectile")
    if projectile ~= nil then
      -- entity.startFiring(projectile)
    else
      -- entity.stopFiring()
    end

    return animator.animationState("movement") == "idle"
  end
end
