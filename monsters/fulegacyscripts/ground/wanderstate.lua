wanderState = {}

function wanderState.enterWith(params)
  if not params.wander then return nil end
  
  return wanderState.enter()
end

function wanderState.enter()
  if hasTarget() or isCaptive() then return nil end

  return {
    wanderTimer = entity.randomizeParameterRange("wanderTime"),
    wanderMovementTimer = entity.randomizeParameterRange("wanderMovementTime"),
    wanderFlipTimer = 0,
    movement = util.randomDirection()
  }
end

function wanderState.update(dt, stateData)
  if hasTarget() then return true end

  if self.territory ~= 0 then
    if isBlocked() or willFall() then
      storage.basePosition = self.position
    else
      stateData.movement = self.territory
      stateData.wanderTimer = entity.randomizeParameterRange("wanderTime")
      stateData.wanderMovementTimer = entity.randomizeParameterRange("wanderMovementTime")
    end
  elseif stateData.movement ~= 0 and (willFall() or isBlocked()) then
    if math.random() < entity.configParameter("wanderJumpProbability", 0) then
      controlJump()
    elseif stateData.wanderFlipTimer <= 0 then
      stateData.movement = -stateData.movement
      stateData.wanderTimer = entity.randomizeParameterRange("wanderTime")
      stateData.wanderFlipTimer = entity.configParameter("wanderFlipTimer", 0.5)
    end
  else
    if stateData.wanderTimer <= 0 then
      return true
    end
  end

  if stateData.movement == 0 then
    stateData.movement = stateData.movement + calculateSeparationMovement()
  end

  moveX(stateData.movement, false)

  entity.setAnimationState("attack", "idle")
  if not mcontroller.onGround() then
    entity.setAnimationState("movement", "jump")
  elseif stateData.movement ~= 0 then
    entity.setAnimationState("movement", "walk")
  else
    entity.setAnimationState("movement", "idle")
  end

  if stateData.wanderMovementTimer <= 0 then
    stateData.movement = 0
  end

  stateData.wanderTimer = stateData.wanderTimer - dt
  stateData.wanderMovementTimer = stateData.wanderMovementTimer - dt
  stateData.wanderFlipTimer = stateData.wanderFlipTimer - dt

  return false
end
