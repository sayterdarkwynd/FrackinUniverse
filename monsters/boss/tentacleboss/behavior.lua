--------------------------------------------------------------------------------
function init()
  self.timers = createTimers()

  self.state = stateMachine.create({
    "smashAttack",
    "riseState",
    "followState",
    "rangedAttack",
    "followState",
    "meleeAttack",
    "followState",
  })

  self.state.enteringState = function(stateName)
    self.state.moveStateToEnd(stateName)
  end

  self.state.leavingState = function(stateName)
    self.hoverTimer = nil
  end

  entity.setAggressive(true)

  -- Setup blinking
  for i = 1, 3 do
    local animationStateName = "eye" .. i
    local blinkDelay = entity.randomizeParameterRange("blinkTimeRange")
    self.timers.start(blinkDelay, function()
      local animation = entity.animationState(animationStateName)
      if animation == "open" then
        entity.setAnimationState(animationStateName, "blink")
      end
      return blinkDelay
    end)
  end

  self.state.pickState({ requestedState = "entrance" })
end

--------------------------------------------------------------------------------
function update(dt)
  if not self.state.update(dt) then
    mcontroller.controlFly({ 0, 0 })
  end

  self.timers.tick(dt)
end

--------------------------------------------------------------------------------
function moveTo(destination, maxSpeed)
  moveBy(world.distance(destination, mcontroller.position()), maxSpeed)
end

--------------------------------------------------------------------------------
function moveBy(delta, maxSpeed)
  if maxSpeed ~= nil then
    local speed = world.magnitude(delta)
    delta = vec2.mul(vec2.norm(delta), math.min(speed, maxSpeed))
  end

  mcontroller.setVelocity(vec2.div(delta, script.updateDt()))
end

--------------------------------------------------------------------------------
function hoverOffset(dt)
  if self.hoverTimer == nil then
    self.hoverTimer = 0
  else
    self.hoverTimer = self.hoverTimer + dt
  end

  local angle = 2.0 * math.pi * entity.configParameter("hoverFrequency") * self.hoverTimer
  return entity.configParameter("hoverAmplitude") * math.sin(angle)
end

--------------------------------------------------------------------------------
function findTargets(radius)
  local position = mcontroller.position()
  local targetIds = world.entityQuery(position, radius, {
    -- validTargetOf = entity.id(), -- deprecated, but so is this whole behavior file
    includedTypes = {"creature"},
    order = "nearest"
  })

  -- Prefer an existing target as long as it stays within the search radius
  if self.targetId ~= nil then
    local targetPosition = world.entityPosition(self.targetId)
    if targetPosition ~= nil then
      local distance = world.magnitude(targetPosition, position)
      if distance < radius then
        table.insert(targetIds, self.targetId)
      else
        self.targetId = nil
      end
    else
      self.targetId = nil
    end
  end

  return targetIds
end

--------------------------------------------------------------------------------
function closestCraterOffset(targetPosition)
  local minDistance, bestOffset, bestOffsetIndex = nil, nil, nil

  for index, offset in ipairs(entity.configParameter("craterOffsets")) do
    local distance = world.magnitude(entity.toAbsolutePosition(offset), targetPosition)
    if minDistance == nil or distance < minDistance then
      minDistance = distance
      bestOffset = offset
      bestOffsetIndex = index
    end
  end

  return bestOffset, bestOffsetIndex
end

--------------------------------------------------------------------------------
riseState = {
  riseSpeedFraction = 0.15,
  riseHeight = 18,
  maxRiseTime = 4,
  pauseTime = 2,
}

function riseState.enterWith(params)
  if params.requestedState ~= "rise" then return nil end
  return { initialPosition = mcontroller.position(), timer = 0 }
end

function riseState.update(dt, stateData)
  -- Pause for a bit after rising up
  if stateData.pauseTimer ~= nil then
    if stateData.hoverPosition == nil then
      stateData.hoverPosition = mcontroller.position()
    end
    moveTo(vec2.add(stateData.hoverPosition, { 0, hoverOffset(dt) }))

    if entity.animationState("eye1") == "closed" then
      entity.setAnimationState("eye1", "open")
      entity.setAnimationState("eye2", "open")
      entity.setAnimationState("eye3", "open")
    end

    stateData.pauseTimer = stateData.pauseTimer - dt
    return stateData.pauseTimer <= 0
  end

  local distance = world.magnitude(mcontroller.position(), stateData.initialPosition)
  stateData.timer = stateData.timer + dt
  if distance >= riseState.riseHeight or stateData.timer >= riseState.maxRiseTime then
    stateData.pauseTimer = riseState.pauseTime
  end

  moveBy({ 0, entity.flySpeed() * riseState.riseSpeedFraction })

  return false
end

--------------------------------------------------------------------------------
followState = {
  targetSearchRadius = 30,
  duration = 10,
  heightOffset = 15,
  trackTargetXInterval = 0.25,
  trackTargetYInterval = 1,
  moveSpeedFraction = 0.1,
}

followState.enter = function()
  local targetIds = findTargets(followState.targetSearchRadius)
  if #targetIds > 0 then
    return {
      timer = followState.duration,
      targetId = targetIds[1],
      targetPosition = world.entityPosition(targetIds[1]),
      trackTargetXTimer = followState.trackTargetXInterval,
      trackTargetYTimer = followState.trackTargetYInterval,
    }
  end

  return nil
end

followState.update = function(dt, stateData)
  local targetPosition = world.entityPosition(stateData.targetId)
  if targetPosition == nil then return true end

  stateData.targetPosition[1] = targetPosition[1]
  stateData.trackTargetXTimer = stateData.trackTargetYTimer - dt
  if stateData.trackTargetXTimer <= 0 then
    stateData.targetPosition[1] = targetPosition[1]
    stateData.trackTargetXTimer = followState.trackTargetXInterval
  end

  stateData.trackTargetYTimer = stateData.trackTargetYTimer - dt
  if stateData.trackTargetYTimer <= 0 then
    stateData.targetPosition[2] = targetPosition[2]
    stateData.trackTargetYTimer = followState.trackTargetYInterval
  end

  local followPosition = {
    stateData.targetPosition[1],
    stateData.targetPosition[2] + followState.heightOffset + hoverOffset(dt)
  }
  moveTo(followPosition, entity.flySpeed() * followState.moveSpeedFraction)

  stateData.timer = stateData.timer - dt
  return stateData.timer <= 0
end

--------------------------------------------------------------------------------
-- Rise up a bit (optional), then smash down in the target's vicinity
smashAttack = {
  entranceTargetSearchRadius = 100,
  targetSearchRadius = 50,

  riseSpeedFraction = 0.2,
  riseHeight = 22,
  riseMaxTime = 4,

  smashSpeedFraction = 0.5,
  smashMaxTime = 3,
  smashTargetOffset = { 0, -2 },

  cooldown = 1,

  explosionOffset = { 0, -6.25 },
}

function smashAttack.enter()
  local targetIds = findTargets(smashAttack.targetSearchRadius)
  if #targetIds == 0 then return nil end

  return {
    targetId = targetIds[1],
    targetPosition = world.entityPosition(targetIds[1]),
    riseTimer = smashAttack.riseMaxTime,
  }
end

function smashAttack.enterWith(params)
  -- Called on initial spawn, this is just a version of this state with some
  -- additional effects/options
  if params.requestedState ~= "entrance" then return nil end

  local direction = { 0, -1 }

  local targetIds = findTargets(smashAttack.entranceTargetSearchRadius)
  if #targetIds > 0 then
    direction = smashAttack.targetDirection(targetIds[1])
  end

  return { direction = direction }
end

function smashAttack.update(dt, stateData)
  -- Delay one update after crashing to allow the explosion to trigger
  if stateData.landed then
    self.state.pickState({ requestedState = "rise" })
    return true, smashAttack.cooldown
  end

  local position = mcontroller.position()

  if stateData.riseTimer ~= nil then
    -- Rising up
    if not world.entityExists(stateData.targetId) then return true, smashAttack.cooldown end
    local delta = world.distance(stateData.targetPosition, mcontroller.position())

    if delta[2] < -smashAttack.riseHeight or stateData.riseTimer <= 0 then
      stateData.direction = smashAttack.targetDirection(stateData.targetId)
      stateData.riseTimer = nil
    else
      moveBy({ 0, entity.flySpeed() * smashAttack.riseSpeedFraction })
      stateData.riseTimer = stateData.riseTimer - dt
    end
  else
    -- Smashing down
    local angle = vec2.angle(stateData.direction)
    if stateData.direction[1] < 0 then angle = math.pi - angle end
    entity.rotateGroup("flames", angle + math.pi / 2, true)
    entity.setAnimationState("flames", "idle")

    local delta = vec2.mul(stateData.direction, entity.flySpeed() * smashAttack.smashSpeedFraction)

    moveBy(vec2.mul(vec2.norm(delta), entity.flySpeed() * smashAttack.smashSpeedFraction))

    local bounds = entity.configParameter("metaBoundBox")
    bounds = {
      bounds[1] + position[1] + delta[1],
      bounds[2] + position[2] + delta[2],
      bounds[3] + position[1] + delta[1],
      bounds[4] + position[2] + delta[2]
    }
    moveBy(delta)

    if stateData.smashTimer == nil then
      stateData.smashTimer = smashAttack.smashMaxTime
    end
    stateData.smashTimer = stateData.smashTimer - dt
    if stateData.smashTimer <= 0 then
      self.state.pickState({ requestedState = "rise" })
      return true, smashAttack.cooldown
    end

    if world.rectTileCollision(bounds) then
      -- entity.setFireDirection(smashAttack.explosionOffset, { 0, 0 })
      -- entity.startFiring("crashexplosion")
      stateData.landed = true
    end
  end

  return false
end

function smashAttack.leavingState(stateData)
  -- entity.stopFiring()
  entity.setAnimationState("flames", "hidden")
end

function smashAttack.targetDirection(targetId)
  local targetPosition = vec2.add(world.entityPosition(targetId), smashAttack.smashTargetOffset)
  local toTarget = world.distance(targetPosition, mcontroller.position())
  return vec2.norm(toTarget)
end

--------------------------------------------------------------------------------
rangedAttack = {
  targetSearchRadius = 30,
  duration = 1,
  cooldown = 1,
}

function rangedAttack.enter()
  local targetIds = findTargets(rangedAttack.targetSearchRadius)
  if #targetIds == 0 then return nil end

  return {
    targetId = targetIds[1],
    targetPosition = world.entityPosition(targetIds[1]),
    timer = rangedAttack.duration,
  }
end

function rangedAttack.enteringState(stateData)
  -- local fireOffset = closestCraterOffset(stateData.targetPosition)
  -- entity.setFireDirection(fireOffset, vec2.norm(fireOffset))
  -- entity.startFiring("meteor")
end

function rangedAttack.update(dt, stateData)
  mcontroller.controlFly({ 0, 0 })

  stateData.timer = stateData.timer - dt
  return stateData.timer <= 0, rangedAttack.cooldown
end

function rangedAttack.leavingState(stateData)
  -- entity.stopFiring()
end

--------------------------------------------------------------------------------
meleeAttack = {
  targetSearchRadius = 30,
  targetOffset = { 0, 6 },
  moveSpeedFraction = 0.3,
  tentacleSearchRadius = 12,
  maxTime = 4,
  pauseTime = 2,
  cooldown = 1,
  minDistance = 7,

  projectileLifetime = 0.5,
}

function meleeAttack.enter()
  local targetIds = findTargets(meleeAttack.targetSearchRadius)
  if #targetIds == 0 then return nil end

  return {
    targetId = targetIds[1],
    targetPosition = vec2.add(world.entityPosition(targetIds[1]), meleeAttack.targetOffset),
    timer = meleeAttack.maxTime,
    tentacleProjectileEntityIds = { nil, nil, nil, nil, nil, nil, nil, nil }
  }
end

function meleeAttack.update(dt, stateData)
  local targetIds = findTargets(meleeAttack.tentacleSearchRadius)
  for _, targetId in pairs(targetIds) do
    local _, index = closestCraterOffset(world.entityPosition(targetId))
    local animationStateName = "tentacle" .. index
    if entity.animationState(animationStateName) == "hidden" then
      entity.setAnimationState(animationStateName, "extend")
    end
  end

  local craterOffsets = entity.configParameter("craterOffsets")
  for i = 1, 8 do
    local animationStateName = "tentacle" .. i
    local animation = entity.animationState(animationStateName)
    if animation == "idle" then
      if stateData.tentacleProjectileEntityIds[i] == nil or not world.entityExists(stateData.tentacleProjectileEntityIds[i]) then
        stateData.tentacleProjectileEntityIds[i] = world.spawnProjectile("tentaclecomet" .. i, mcontroller.position(), entity.id(), craterOffsets[i], true, {
          speed = 0,
          power = 20,
          timeToLive = meleeAttack.projectileLifetime
        })
      end
    end
  end

  if stateData.pauseTimer ~= nil then
    if stateData.hoverPosition == nil then
      stateData.hoverPosition = mcontroller.position()
    end
    moveTo(vec2.add(stateData.hoverPosition, { 0, hoverOffset(dt) }))

    stateData.pauseTimer = stateData.pauseTimer - dt
    return stateData.pauseTimer <= 0, meleeAttack.cooldown
  end

  local distance = world.magnitude(stateData.targetPosition, mcontroller.position())
  if distance <= meleeAttack.minDistance or stateData.timer <= 0 then
    stateData.pauseTimer = meleeAttack.pauseTime
  else
    moveTo(stateData.targetPosition, entity.flySpeed() * meleeAttack.moveSpeedFraction)
  end

  return false
end

function meleeAttack.leavingState(stateData)
  for i = 1, 8 do
    local animationStateName = "tentacle" .. i
    if entity.animationState(animationStateName) ~= "hidden" then
      entity.setAnimationState(animationStateName, "retract")
    end
  end
end
