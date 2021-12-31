function init()
  self.sensors = sensors.create()

  self.state = stateMachine.create({
    "moveState",
    "repairState",
    "attackState"
  })

  entity.setAggressive(false)
  entity.setDeathParticleBurst("deathPoof")
  animator.setAnimationState("movement", "idle")
end

function update(dt)
  local repairTargetId = repairState.findTaget()
  if repairTargetId ~= nil then
    self.state.pickState({ repairTargetId = repairTargetId })
  end

  self.state.update(dt)
  self.sensors.clear()
end

function damage(args)
  if entity.health() > 0 then
    self.state.pickState({ damageSourceId = args.sourceId })
  end
end

function isOnPlatform()
  return mcontroller.onGround() and
      not self.sensors.nearGroundSensor.collisionTrace.any(true) and
      self.sensors.midGroundSensor.collisionTrace.any(true)
end

function move(toTarget)
  setAnimation("move")

  if math.abs(toTarget[2]) < 4.0 and isOnPlatform() then
    mcontroller.controlDown()
  end

  mcontroller.controlMove(toTarget[1], true)
end

function setAnimation(desiredAnimation)
  local animation = entity.animationState("movement")
  if animation == desiredAnimation then
    return true
  end

  if desiredAnimation == "attack" then
    if animation ~= "attack" and animation ~= "attackStart" then
      animator.setAnimationState("movement", "attackStart")
    end
  elseif desiredAnimation == "repair" then
    if animation ~= "repair" and animation ~= "repairStart" then
      animator.setAnimationState("movement", "repairStart")
    end
  else
    if animation == "attack" or animation == "attackStart" then
      animator.setAnimationState("movement", "attackEnd")
    elseif animation == "repair" or animation == "repairStart" then
      animator.setAnimationState("movement", "repairEnd")
    elseif animation ~= "attackEnd" and animation ~= "repairEnd" then
      animator.setAnimationState("movement", desiredAnimation)
    end
  end

  return false
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

  move({ stateData.direction, 0 })

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, entity.randomizeParameterRange("idleTimeRange")
  end

  return false
end

--------------------------------------------------------------------------------
repairState = {}

function repairState.enterWith(params)
  if params.repairTargetId == nil then return nil end

  return { targetId = params.repairTargetId }
end

function repairState.update(dt, stateData)
  local targetPosition = world.entityPosition(stateData.targetId)
  if targetPosition == nil then
    return setAnimation("move")
  end

  local targetHealthStatus = world.entityHealth(stateData.targetId)
  if targetHealthStatus[1] == 0 or targetHealthStatus[1] == targetHealthStatus[2] then
    return setAnimation("move")
  end

  local toTarget = world.distance(targetPosition, mcontroller.position())
  if world.magnitude(toTarget) < config.getParameter("repairDistance") then
    if setAnimation("repair") then
      entity.heal(stateData.targetId, config.getParameter("repairHealthPerSecond") * dt)
    end
  else
    if setAnimation("move") then
      move(toTarget)
    end
  end

  return false
end

function repairState.findTaget()
  local entityIds = world.entityQuery(mcontroller.position(), config.getParameter("repairResponseMaxDistance"), {includedTypes = {"monster"}})
  local selfId = entity.id()

  for _, entityId in ipairs(entityIds) do
    if entityId ~= selfId then
      local healthStatus = world.entityHealth(entityId)
      if healthStatus[1] < healthStatus[2] then
        return entityId
      end
    end
  end

  return nil
end

--------------------------------------------------------------------------------
attackState = {}

function attackState.enterWith(params)
  if params.damageSourceId == nil then return nil end

  self.targetId = params.damageSourceId
  return { timer = config.getParameter("attackTargetHoldTime") }
end

function attackState.update(dt, stateData)
  util.trackExistingTarget()

  entity.setAggressive(true)

  local shouldFire = false
  if self.targetPosition ~= nil then
    local toTarget = world.distance(self.targetPosition, mcontroller.position())
    local attackRange = config.getParameter("attackRange")
    local distance = world.magnitude(toTarget)

    if distance < attackRange[1] then
      if setAnimation("move") then
        move({ -toTarget[1], 0 })
      end
    elseif distance > attackRange[2] then
      if setAnimation("move") then
        move({ toTarget[1], 0 })
      end
    else
      mcontroller.controlFace(toTarget[1])
      if setAnimation("attack") then
        -- entity.setFireDirection(config.getParameter("projectileOffset"), { mcontroller.facingDirection(), 0 })
        shouldFire = true
      end
    end
  end

  if shouldFire then
    -- if not entity.isFiring() then
    --   entity.startFiring("projectile")
    -- end
  else
    -- entity.stopFiring()
  end

  if self.targetId == nil then
    stateData.timer = stateData.timer - dt
  else
    stateData.timer = config.getParameter("attackTargetHoldTime")
  end

  if stateData.timer <= 0 then
    entity.setAggressive(false)
    return true
  else
    return false
  end
end
