attackState = {}

function attackState.enter()
  if not self.target or not targetValid(self.target) then
    return nil
  end

  return { timer = entity.configParameter("attackApproachTime"), stage = "approach" }
end

function attackState.enteringState(stateData)
  -- world.logInfo("Entering attack state")
end

function attackState.update(dt, stateData)
  if not self.target then return true end

  stateData.timer = stateData.timer - dt
  
  local toTarget = entity.distanceToEntity(self.target)

  if stateData.stage == "approach" then
    move(toTarget, true)
    if vec2.mag(toTarget) <= entity.configParameter("attackStartDistance") then
      -- world.logInfo("winding up...")
      stateData.stage = "windup"
      stateData.timer = entity.configParameter("attackWindupTime")
    end
  elseif stateData.stage == "windup" then
    entity.setAnimationState("movement", "swimSlow")
    setBodyDirection(toTarget)
    if stateData.timer <= 0 then
      -- world.logInfo("charging...")
      stateData.stage = "charge"
      entity.setAnimationState("attack", "melee")
      stateData.chargeDirection = toTarget
      stateData.timer = entity.configParameter("attackChargeTime")
    end
  elseif stateData.stage == "charge" then
    if collides("blockedSensors") then return true end

    if entity.animationState("attack") == "melee" then
      entity.setDamageOnTouch(true)
      mcontroller.controlParameters({flySpeed = entity.configParameter("attackChargeSpeed")})
      move(stateData.chargeDirection, true, true)
    else
      entity.setDamageOnTouch(false)
      move(stateData.chargeDirection, false)
    end
  end
  
  return stateData.timer <= 0
end

function attackState.leavingState(stateData)
  entity.setDamageOnTouch(false)
end
