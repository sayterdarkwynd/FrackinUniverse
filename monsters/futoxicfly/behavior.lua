--------------------------------------------------------------------------------
function init()
  self.sensors = sensors.create()

  self.state = stateMachine.create({
    "idleState",
    "moveState",
    "attackState"
  })
  self.state.enteringState = function(stateName)
    self.state.shuffleStates()
  end

  self.state.leavingState = function(stateName)
    monster.setAggressive(false)
  end

  monster.setAggressive(false)
end

--------------------------------------------------------------------------------
function update(dt)
  if util.trackTarget(30) then
    self.state.pickState({ targetId = self.targetId })
  end

  if not self.state.update(dt) then
    mcontroller.controlFly({ 0, 0 })
  end

  if self.state.stateDesc() ~= "attackState" then
    if mcontroller.onGround() then
      animator.setAnimationState("movement", "idle")
    else
      animator.setAnimationState("movement", "fly")
    end
  end

  self.sensors.clear()
end

--------------------------------------------------------------------------------
function damage(args)
  if entity.health() > 0 then
    self.state.pickState({ targetId = args.sourceId })
  end
end

--------------------------------------------------------------------------------
idleState = {}

function idleState.enter()
  if mcontroller.onGround() or self.sensors.idleLandSensor.collisionTrace.any(true) then
    return { timer = entity.randomizeParameterRange("idleTimeRange") }
  end

  return nil
end

function idleState.update(dt, stateData)
  if not mcontroller.onGround() then
    if not self.sensors.idleLandSensor.collisionTrace.any(true) then
      return true, config.getParameter("idleCooldown")
    end

    mcontroller.controlFly({0,  -entity.flySpeed() / 2 })
  end

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, config.getParameter("idleCooldown")
  end
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  return {
    timer = entity.randomizeParameterRange("moveTimeRange"),
    direction = util.randomDirection()
  }
end

function moveState.update(dt, stateData)
  if self.sensors.blockedSensors.collision.any(true) then
    stateData.direction = -stateData.direction
  end

  local delta = { stateData.direction, 0 }
  if self.sensors.moveGroundSensor.collisionTrace[1].value then
    delta[2] = 0.5
  elseif self.sensors.moveCeilingSensor.collisionTrace[1].value then
    delta[2] = -0.5
  end

  delta = vec2.mul(vec2.norm(delta), entity.flySpeed())
  mcontroller.controlFly(delta, true)

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true
  end

  return false
end

--------------------------------------------------------------------------------
attackState = {}

function attackState.enterWith(args)
  if args.targetId ~= nil then
    return nil -- TODO
  end

  return nil
end

function attackState.enteringState(stateData)
  monster.setAggressive(true)
end

function attackState.update(dt, stateData)
  return true -- TODO
end
