-- Land on the ground and chill out for a while

landState = {}

function landState.enter()
  if hasTarget() then return nil end

  if not self.sensors.groundSensors.collisionTrace[3].value then
    return nil
  end

  if entity.closestValidTarget(entity.configParameter("landDisturbDistance")) ~= 0 then
    return nil
  end

  return { restTime = entity.randomizeParameterRange("landRestTimeRange") }
end

function landState.update(dt, stateData)
  if hasTarget() then return true end

  if entity.closestValidTarget(entity.configParameter("landDisturbDistance")) ~= 0 then
    return true, entity.randomizeParameterRange("landCooldownTimeRange")
  end

  if mcontroller.onGround() then
    entity.setAnimationState("movement", "standing")

    stateData.restTime = stateData.restTime - dt
    if stateData.restTime < 0.0 then
      return true, entity.randomizeParameterRange("landCooldownTimeRange")
    end
  else
    entity.setAnimationState("movement", "flying")
    mcontroller.controlFly({ 0, -mcontroller.baseParameters().flySpeed * entity.configParameter("wanderSpeedMultiplier") }, true)
  end

  return false
end
