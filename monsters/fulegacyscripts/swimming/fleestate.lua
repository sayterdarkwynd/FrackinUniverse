fleeState = {}

function fleeState.enterWith(params)
  if not params.flee then return nil end

  local toTarget = vec2.norm(entity.distanceToEntity(self.target))

  return { timer = entity.randomizeParameterRange("fleeTimeRange"), fleeDirection = {-toTarget[1], -toTarget[2]} }
end

function fleeState.enteringState(stateData)
  -- world.logInfo("Entering flee state")
end

function fleeState.update(dt, stateData)
  if collides("upSensors") then
    stateData.fleeDirection[2] = stateData.fleeDirection[2] + 0.1
  elseif collides("downSensors") then
    stateData.fleeDirection[2] = stateData.fleeDirection[2] - 0.1
  elseif collides("blockedSensors") then
    stateData.fleeDirection[1] = -stateData.fleeDirection[1]
  end

  stateData.fleeDirection = vec2.norm(stateData.fleeDirection)

  move(stateData.fleeDirection, true)

  stateData.timer = stateData.timer - dt
  return stateData.timer <= 0
end

function fleeState.leavingState(stateData)
  setTarget(false)
end
