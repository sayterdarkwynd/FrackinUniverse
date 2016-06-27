--------------------------------------------------------------------------------
wanderState = {}

function wanderState.enter()
  if hasTarget() then return nil end

  return {
    direction = util.randomDirection(),
    timer = entity.randomizeParameterRange("wander.moveTimeRange")
  }
end

function wanderState.enterWith(args)
  if args.wander then return wanderState.enter() end
end

function wanderState.enteringState(stateData)
end

function wanderState.update(dt, stateData)
  crawl(stateData.direction)

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, entity.randomizeParameterRange("wander.moveCooldownRange")
  else
    return false
  end
end

function wanderState.leavingState(stateData)
end