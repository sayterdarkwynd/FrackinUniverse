wanderState = {}

function wanderState.enterWith(params)
  if not params.wander then return nil end

  return wanderState.enter()
end

function wanderState.enter()
  if hasTarget() or isCaptive() then return nil end

  return {
    wanderTimer = util.randomInRange(config.getParameter("wanderTime")),
    wanderMovementTimer = util.randomInRange(config.getParameter("wanderMovementTime")),
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
      stateData.wanderTimer = util.randomInRange(config.getParameter("wanderTime"))
      stateData.wanderMovementTimer = util.randomInRange(config.getParameter("wanderMovementTime"))
    end
  elseif stateData.movement ~= 0 and (willFall() or isBlocked()) then
    if math.random() < config.getParameter("wanderJumpProbability", 0) then
      controlJump()
    elseif stateData.wanderFlipTimer <= 0 then
      stateData.movement = -stateData.movement
      stateData.wanderTimer = util.randomInRange(config.getParameter("wanderTime"))
      stateData.wanderFlipTimer = config.getParameter("wanderFlipTimer", 0.5)
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

  animator.setAnimationState("attack", "idle")
  if not mcontroller.onGround() then
    animator.setAnimationState("movement", "jump")
  elseif stateData.movement ~= 0 then
    animator.setAnimationState("movement", "walk")
  else
    animator.setAnimationState("movement", "idle")
  end

  if stateData.wanderMovementTimer <= 0 then
    stateData.movement = 0
  end

  stateData.wanderTimer = stateData.wanderTimer - dt
  stateData.wanderMovementTimer = stateData.wanderMovementTimer - dt
  stateData.wanderFlipTimer = stateData.wanderFlipTimer - dt

  return false
end
