-- Land on the ground and chill out for a while

landState = {}

function landState.enter()
  if hasTarget() then return nil end

  if not self.sensors.groundSensors.collisionTrace[3].value then
    return nil
  end

  if util.closestValidTarget(config.getParameter("landDisturbDistance")) ~= 0 then
    return nil
  end

  return { restTime = util.randomInRange(config.getParameter("landRestTimeRange")) }
end

function landState.update(dt, stateData)
  if hasTarget() then return true end

  if util.closestValidTarget(config.getParameter("landDisturbDistance")) ~= 0 then
    return true, util.randomInRange(config.getParameter("landCooldownTimeRange"))
  end

  if mcontroller.onGround() then
    animator.setAnimationState("movement", "standing")

    stateData.restTime = stateData.restTime - dt
    if stateData.restTime < 0.0 then
      return true, util.randomInRange(config.getParameter("landCooldownTimeRange"))
    end
  else
    animator.setAnimationState("movement", "flying")
    mcontroller.controlFly({ 0, -mcontroller.baseParameters().flySpeed * config.getParameter("wanderSpeedMultiplier") }, true)
  end

  return false
end
