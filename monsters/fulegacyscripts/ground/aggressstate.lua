aggressState = {}

function aggressState.enter()
  if hasTarget() and not canStartAttack() then
    return {}
  end

  return nil
end

function aggressState.enteringState(stateData)
  self.exhaustionTimer = entity.configParameter("exhaustionTimer")
end

function aggressState.update(dt, stateData)
  local closeDistance = entity.configParameter("closeDistance")
  local movement
  if math.abs(self.toTarget[1]) < closeDistance then
    movement = 0
  elseif self.toTarget[1] < 0 then
    movement = -1
  elseif self.toTarget[1] > 0 then
    movement = 1
  end

  local onGround = mcontroller.onGround()

  -- Don't bunch up with other monsters if we are close enough
  if self.jumpTimer <= 0 and onGround and movement == 0 then
    movement = calculateSeparationMovement()
  end

  entity.setAnimationState("attack", "idle")
  move({ movement, self.toTarget[2] }, true, closeDistance)

  -- Keep track of when we hit the ground in aggress, and if we keep ending up
  -- in the same place, decrement our exhaustion timer.
  if onGround then
    local distance = world.distance(self.position, self.lastAggressGroundPosition)
    if math.max(math.abs(distance[1]), math.abs(distance[2])) > entity.configParameter("exhaustionDistanceLimit") then
      self.exhaustionTimer = entity.configParameter("exhaustionTimer")
      self.lastAggressGroundPosition = self.position
    end
  end

  -- If our exhaustion timer has run out, reset it, and set the exhaustion
  -- *cooldown timer* which will trigger exhaustion wander()
  self.exhaustionTimer = self.exhaustionTimer - dt

  if self.exhaustionTimer <= 0 then
    self.exhaustionTimer = entity.configParameter("exhaustionTimer")
    self.exhaustionCooldownTimer = entity.configParameter("exhaustionCooldownTimer", 0)
    return true, self.exhaustionCooldownTimer
  end

  return false
end
