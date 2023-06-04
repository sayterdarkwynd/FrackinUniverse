attackState = {}

function attackState.enter()
  if not self.target or not targetValid(self.target) then
    return nil
  end

  return { timer = config.getParameter("attackApproachTime"), stage = "approach" }
end

function attackState.enteringState(stateData)
  -- sb.logInfo("Entering attack state")
end

function attackState.update(dt, stateData)
  if not self.target then return true end

  stateData.timer = stateData.timer - dt

  local toTarget = entity.distanceToEntity(self.target)

  if stateData.stage == "approach" then
    move(toTarget, true)
    if vec2.mag(toTarget) <= config.getParameter("attackStartDistance") then
      -- sb.logInfo("winding up...")
      stateData.stage = "windup"
      stateData.timer = config.getParameter("attackWindupTime")
    end
  elseif stateData.stage == "windup" then
    animator.setAnimationState("movement", "swimSlow")
    setBodyDirection(toTarget)
    if stateData.timer <= 0 then
      -- sb.logInfo("charging...")
      stateData.stage = "charge"
      animator.setAnimationState("attack", "melee")
      stateData.chargeDirection = toTarget
      stateData.timer = config.getParameter("attackChargeTime")
    end
  elseif stateData.stage == "charge" then
    if collides("blockedSensors") then return true end

    if animator.animationState("attack") == "melee" then
      monster.setDamageOnTouch(true)
      mcontroller.controlParameters({flySpeed = config.getParameter("attackChargeSpeed")})
      move(stateData.chargeDirection, true, true)
    else
      monster.setDamageOnTouch(false)
      move(stateData.chargeDirection, false)
    end
  end

  return stateData.timer <= 0
end

function attackState.leavingState(stateData)
  monster.setDamageOnTouch(false)
end
