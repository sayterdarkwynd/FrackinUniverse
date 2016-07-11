--------------------------------------------------------------------------------
idleState = {}

function idleState.enter()
  if hasTarget() then return nil end

  return {
    timer = util.randomInRange(config.getParameter("idle.idleTimeRange"))
  }
end

function idleState.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
end

function idleState.update(dt, stateData)
  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    return true, 0
  else
    return false
  end
end

function idleState.leavingState(stateData)
end