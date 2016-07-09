require "/scripts/util.lua"

-- Move in a flattened circle (ellipse) around a point above the target
glideState = {}

function glideState.enter()
  if hasTarget() then return nil end

  if self.sensors.groundSensors.collisionTrace[4].value then
    return nil
  end

  return {
    timer = config.getParameter("glideTime"),
    baseDirection = mcontroller.facingDirection()
  }
end

function glideState.update(dt, stateData)
  if hasTarget() then return true end

  if self.sensors.groundSensors.collisionTrace[2].value or stateData.timer < 0 then
    return true, config.getParameter("glideCooldownTime")
  end
  stateData.timer = stateData.timer - dt

  animator.setAnimationState("movement", "gliding")

  local vector = {
    stateData.baseDirection,
    -config.getParameter("glideSinkingSpeed")
  }

  --don't turn around immediately before switching states
  if stateData.timer > 0.5 then
    util.toDirection(math.sin(config.getParameter("glideSpiralDispersion") * math.pi * 2.0 * stateData.timer))
  end

  if self.sensors.blockedSensors.collision.any(true) then
    stateData.baseDirection = -stateData.baseDirection
    vector[1] = -vector[1]
  end

  -- util.debugLine(mcontroller.position(), monster.toAbsolutePosition(vector), "cornflowerblue")
  mcontroller.controlFly(vec2.mul(vector, mcontroller.baseParameters().flySpeed), true)

  return false
end
