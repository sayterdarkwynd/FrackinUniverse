wanderState = {}

function wanderState.enter()
  if self.target then return nil end

  if self.wanderDirection == nil then
    self.wanderDirection = { util.randomDirection(), 0 }
  else
    self.wanderDirection = { util.toDirection(mcontroller.facingDirection()), 0 }
  end

  if self.wanderTime == nil then
    self.wanderTime = util.randomInRange(config.getParameter("wanderTime"))
  end

  return { }
end

function wanderState.enteringState(stateData)
  -- sb.logInfo("Entering wander state")
end

function wanderState.update(dt, stateData)
  if self.target then return true end

  self.wanderTime = self.wanderTime - dt
  if self.wanderTime <= 0 or util.blockSensorTest("blockedSensors", self.wanderDirection[1]) then
    self.wanderDirection[1] = -self.wanderDirection[1]
    self.wanderTime = util.randomInRange(config.getParameter("wanderTime"))
  end

  move(self.wanderDirection, false)

  return false
end

function wanderState.leavingState(stateData)

end
