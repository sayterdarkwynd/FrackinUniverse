require "/scripts/companions/capturable.lua"
require "/scripts/util.lua"

function init()
  self.sensors = sensors.create()

  self.state = stateMachine.create({
    "moveState",
    "attackState"
  })

  self.state.leavingState = function(stateName)
    animator.setAnimationState("movement", "idle")
  end

  message.setHandler("swarpionFlockInfo", function()
      return {
        movement = self.movement,
        isLeader = self.isFlockLeader
      }
    end)

  monster.setDeathParticleBurst("deathPoof")
  capturable.init()
end

--------------------------------------------------------------------------------
function update(dt)
  capturable.update(dt)
  if util.trackTarget(config.getParameter("targetNoticeDistance")) then
    self.state.pickState(self.targetId)
  end

  self.movement = { 0, 0 }
  self.state.update(dt)

  if animator.animationState("movement") ~= "attack" then
    local flockMovement = flocking.calculateMovement("swarpionFlockInfo")
    local movements = { { self.movement, 1.0 } }

    if not self.isFlockLeader then
      table.insert(movements, { flockMovement, config.getParameter("flockMovementWeight") })
    end

    local combinedMovement = { 0, 0 }
    for _, movementComponent in ipairs(movements) do
      local movement, weight = table.unpack(movementComponent)
      combinedMovement = vec2.add(combinedMovement, vec2.mul(movement, weight))
    end

    self.movement = vec2.norm(combinedMovement)
    move(self.movement)
  end

  self.sensors.clear()
end

--------------------------------------------------------------------------------
function die()
  capturable.die()
end

function shouldDie()
  return status.resource("health") <= 0 or capturable.justCaptured
end

--------------------------------------------------------------------------------
function isOnPlatform()
  return mcontroller.onGround() and
      not self.sensors.nearGroundSensor.collisionTrace.any(true) and
      self.sensors.midGroundSensor.collisionTrace.any(true)
end

--------------------------------------------------------------------------------
function move(toTarget)
  animator.setAnimationState("movement", "move")

  if math.abs(toTarget[2]) < 4.0 and isOnPlatform() then
    mcontroller.controlDown()
  end

  mcontroller.controlMove(toTarget[1], true)
end

--------------------------------------------------------------------------------
moveState = {}

function moveState.enter()
  return {
    timer = util.randomInRange(config.getParameter("moveTimeRange")),
    direction = util.randomDirection()
  }
end

function moveState.update(dt, stateData)
  if self.sensors.collisionSensors.collision.any(true) then
    stateData.direction = -stateData.direction
  end

  move({ stateData.direction, 0 })

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, util.randomInRange(config.getParameter("idleTimeRange"))
  end

  return false
end

--------------------------------------------------------------------------------
attackState = {}

function attackState.enterWith(targetId)
  if targetId == nil then return nil end

  monster.setAggressive(true)
  return {
    timer = config.getParameter("attackTargetHoldTime"),
    attackPauseTimer = 0,
    lastTargetPosition = self.targetPosition
  }
end

function attackState.update(dt, stateData)
  if animator.animationState("movement") == "attack" then
    monster.setDamageOnTouch(true)
    return false
  end
  monster.setDamageOnTouch(false)

  if stateData.attackPauseTimer > 0 then
    stateData.attackPauseTimer = math.max(0, stateData.attackPauseTimer - dt)
    return false
  end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local distance = world.magnitude(toTarget)

  local attackRange = config.getParameter("attackRange")
  if distance < attackRange[1] then
    self.movement = { -toTarget[1], toTarget[2] }
  elseif distance > attackRange[2] then
    self.movement = toTarget
  else
    stateData.attackPauseTimer = config.getParameter("attackPauseTime")
    animator.setAnimationState("movement", "attack")
    monster.setDamageOnTouch(true)
    mcontroller.controlFace(toTarget[1])
  end

  if self.targetId == nil then
    stateData.timer = stateData.timer - dt
  else
    stateData.timer = config.getParameter("attackTargetHoldTime")
  end

  return stateData.timer <= 0
end

function attackState.leavingState(stateData)
  monster.setAggressive(false)
  monster.setDamageOnTouch(false)
end
