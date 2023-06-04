function init()
  self.sensors = sensors.create()

  self.state = stateMachine.create({
    "moveState",
    "cleanState",
    "attackState"
  })
  self.state.leavingState = function(stateName)
    animator.setAnimationState("movement", "idle")
  end

  entity.setAggressive(false)
  entity.setDeathParticleBurst("deathPoof")
  animator.setAnimationState("movement", "idle")
end

function update(dt)
  self.state.update(dt)
  self.sensors.clear()
end

function damage(args)
  self.state.pickState(args.sourceId)
end

function move(direction)
  animator.setAnimationState("movement", "move")

  mcontroller.controlMove(direction, true)
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  local direction
  if math.random(100) > 50 then
    direction = 1
  else
    direction = -1
  end

  return {
    timer = entity.randomizeParameterRange("moveTimeRange"),
    direction = direction
  }
end

function moveState.update(dt, stateData)
  if self.sensors.collisionSensors.collision.any(true) then
    stateData.direction = -stateData.direction
  end

  if mcontroller.onGround() and
     not self.sensors.nearGroundSensor.collisionTrace.any(true) and
     self.sensors.midGroundSensor.collisionTrace.any(true) then
    mcontroller.controlDown()
  end

  move(stateData.direction)

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, 1.0
  end

  return false
end

--------------------------------------------------------------------------------
cleanState = {}

function cleanState.enter()
  return { timer = entity.randomizeParameterRange("cleanTimeRange") }
end

function cleanState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  return stateData.timer <= 0
end

--------------------------------------------------------------------------------
attackState = {}

function attackState.enterWith(targetId)
  if targetId == 0 then return nil end

  attackState.setAggressive(targetId)

  return { timer = config.getParameter("attackTargetHoldTime") }
end

function attackState.update(dt, stateData)
  util.trackExistingTarget()

  if self.attackHoldTimer ~= nil then
    self.attackHoldTimer = self.attackHoldTimer - dt
    if self.attackHoldTimer > 0 then
      return false
    else
      self.attackHoldTimer = nil
    end
  end

  if self.targetPosition ~= nil then
    local toTarget = world.distance(self.targetPosition, mcontroller.position())

    if world.magnitude(toTarget) < config.getParameter("attackDistance") then
      attackState.setAttackEnabled(true)
    else
      attackState.setAttackEnabled(false)
      move(util.toDirection(toTarget[1]))
    end
  end

  if self.targetId == nil then
    stateData.timer = stateData.timer - dt
  else
    stateData.timer = config.getParameter("attackTargetHoldTime")
  end

  if stateData.timer <= 0 then
    attackState.setAttackEnabled(false)
    attackState.setAggressive(nil)
    return true
  else
    return false
  end
end

function attackState.setAttackEnabled(enabled)
  if enabled then
    animator.setAnimationState("movement", "attack")
    self.attackHoldTimer = config.getParameter("attackHoldTime")
  else
    animator.setAnimationState("movement", "aggro")
  end

  entity.setDamageOnTouch(enabled)
end

function attackState.setAggressive(targetId)
  self.targetId = targetId

  if targetId ~= nil then
    animator.setAnimationState("movement", "aggro")
    entity.setAggressive(true)
  else
    animator.setAnimationState("movement", "idle")
    entity.setAggressive(false)
  end
end
