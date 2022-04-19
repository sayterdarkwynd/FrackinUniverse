require "/scripts/util.lua"

-- Move in a flattened circle (ellipse) around a point above the target
circleState = {}

function circleState.enter()
  if not hasTarget() then return nil end

  return {
    timer = config.getParameter("circleTime"),
    a = util.randomInRange(config.getParameter("circleWidthRange")),
    b = config.getParameter("circleHeight"),
    yOffset = util.randomInRange(config.getParameter("circleOffsetYRange"))
  }
end

function circleState.enteringState(stateData)
  if not self.circleYOffsetFactor then
    self.circleYOffsetFactor = 1
  end
end

function circleState.update(dt, stateData)
  if not hasTarget() then return true end
  if stateData.timer < 0 then return true end

  -- Advance timer through to the next quarter of the circle if running
  -- in to an impedence, which will switch the direction
  if util.blockSensorTest("blockedSensors") then
    stateData.timer = stateData.timer - config.getParameter("circleTime") * 0.25
  end

  --Lower circle height if we're near ceiling
  for _, ceilingSensorIndex in ipairs({ 3, 2, 1 }) do
    local sensor = self.sensors.ceilingSensors.collisionTrace[ceilingSensorIndex]
    if sensor.value then
      self.circleYOffsetFactor = self.circleYOffsetFactor - 0.75 * dt
    end
  end
  --Also keep adding height
  if self.circleYOffsetFactor < 1 then
    self.circleYOffsetFactor = self.circleYOffsetFactor + dt
  end
  --Don't go too low
  if self.circleYOffsetFactor < 0.1 then
    self.circleYOffsetFactor = 0.1
  end

  local toTarget = entity.distanceToEntity(self.target)
  toTarget[2] = toTarget[2] + stateData.yOffset * self.circleYOffsetFactor

  local ratio = stateData.timer / config.getParameter("circleTime")
  local phase = math.pi * 2.0 * (1.0 - ratio)

  local x = stateData.a * math.cos(phase)
  local y = stateData.b * math.sin(phase)

  -- The circle gets tilted up while climbing and down while gliding to
  -- emphasize the gain and loss of altitude
  local tiltRatio

  if ratio > 0.75 then
    -- Initial quarter of circle; climbing (1.0 -> 0.75) => (0.0 -> 1.0)
    tiltRatio = 1.0 - (ratio - 0.75) * 4.0
  elseif ratio < 0.25 then
    -- Last quarter of circle; climing (0.25 -> 0.0) => (-2.0 -> 0.0)
    tiltRatio = ratio * -8.0
  else
    -- Middle half of circle; gliding (0.75 -> 0.25) => (1.0 -> -2.0)
    tiltRatio = (ratio - 0.25) * 6.0 - 2.0
  end

  local destination = {
    self.position[1] + toTarget[1] + x,
    self.position[2] + toTarget[2] + y + tiltRatio * config.getParameter("circleTiltRadius")
  }

  local movement = world.distance(destination, self.position)

  if movement[2] < 0 then
    animator.setAnimationState("movement", "gliding")
  else
    animator.setAnimationState("movement", "flying")
  end

  util.debugLine(mcontroller.position(), destination, "blue")
  monster.flyTo(destination, true)

  stateData.timer = stateData.timer - dt
  return false
end
