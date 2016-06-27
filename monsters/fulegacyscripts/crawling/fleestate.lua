fleeState = {
  minDuration = 1,
  maxDuration = 4
}

function fleeState.enterWith(params)
  if not params.flee then return nil end

  local direction
  if hasTarget() then
    direction = self.toTarget[1] < 0 and 1 or -1
  else
    direction = -mcontroller.facingDirection()
  end

  return { direction = direction, timer = 0, duration = params.duration or math.random(fleeState.minDuration, fleeState.maxDuration) }
end

function fleeState.enteringState(stateData)
end

function fleeState.update(dt, stateData)
  if checkStuck() % 5 == 4 then
    stateData.direction = -stateData.direction
  end

  move({ stateData.direction, 0 }, true)

  stateData.timer = stateData.timer + dt
  return stateData.timer > stateData.duration
end

function fleeState.leavingState(stateData)
end
