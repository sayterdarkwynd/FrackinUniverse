-- Move in a flattened circle (ellipse) around a point above the target
turnState = {}

function turnState.enter()
  if hasTarget() then return nil end

  return {
    timer = config.getParameter("turnTime"),
    baseDirection = mcontroller.facingDirection()
  }
end

function turnState.update(dt, stateData)
  if hasTarget() then return true end
  if stateData.timer < 0 then return true end

  local ratio = stateData.timer / config.getParameter("turnTime")
  local phase = math.pi * (1.0 - ratio)

  -- Advance timer through to the next quarter of the circle if running
  -- in to an impedence, which will switch the direction
  if util.blockSensorTest("blockedSensors") then
    if ratio >= 0.5 then
      stateData.baseDirection = -stateData.baseDirection
    end

    stateData.timer = stateData.timer - config.getParameter("turnTime") * 0.25
  end

  local movement = {
    math.cos(phase) * mcontroller.baseParameters().flySpeed * config.getParameter("wanderSpeedMultiplier") * stateData.baseDirection,
    -math.sin(phase) * mcontroller.baseParameters().flySpeed * config.getParameter("wanderSpeedMultiplier") * config.getParameter("turnTiltRatio")
  }

  -- local toTarget = entity.distanceToEntity(self.target)
  -- toTarget[2] = toTarget[2] + stateData.yOffset



  -- local x = stateData.a * math.cos(phase)
  -- local y = stateData.b * math.sin(phase)

  -- -- The circle gets tilted up while climbing and down while gliding to
  -- -- emphasize the gain and loss of altitude
  -- local tiltRatio = 0

  -- if ratio > 0.75 then
  --   -- Initial quarter of circle; climbing (1.0 -> 0.75) => (0.0 -> 1.0)
  --   tiltRatio = 1.0 - (ratio - 0.75) * 4.0
  -- elseif ratio < 0.25 then
  --   -- Last quarter of circle; climing (0.25 -> 0.0) => (-2.0 -> 0.0)
  --   tiltRatio = ratio * -8.0
  -- else
  --   -- Middle half of circle; gliding (0.75 -> 0.25) => (1.0 -> -2.0)
  --   tiltRatio = (ratio - 0.25) * 6.0 - 2.0
  -- end

  -- local destination = {
  --   self.position[1] + toTarget[1] + x,
  --   self.position[2] + toTarget[2] + y + tiltRatio * config.getParameter("circleTiltRadius")
  -- }

  -- local movement = world.distance(destination, self.position)

  if movement[2] < 0 then
    animator.setAnimationState("movement", "gliding")
  else
    animator.setAnimationState("movement", "flying")
  end

  mcontroller.controlFly(movement, true)

  stateData.timer = stateData.timer - dt
  return false
end
