flopState = {}

function flopState.enter()
  if mcontroller.liquidMovement() then return nil end

  return { }
end

function flopState.enterWith(parameters)
  if mcontroller.liquidMovement() or not parameters.flop then return nil end

  return { jumpTimer = 0, jumpDirection = 1 }
end

function flopState.enteringState(stateData)
  -- sb.logInfo("Entering flop state")

  animator.setAnimationState("movement", "flopping")
end

function flopState.update(dt, stateData)
  if mcontroller.liquidMovement() then return true end

  mcontroller.controlParameters({ bounceFactor = 0.9 })

  stateData.jumpTimer = stateData.jumpTimer - dt
  if mcontroller.onGround() then
    if stateData.jumpTimer <= 0 then
      stateData.jumpDirection = util.randomDirection()
      mcontroller.controlMove(stateData.jumpDirection)
      mcontroller.controlJump()
    else
      mcontroller.controlDown()
    end
  end

  if stateData.jumpTimer <= 0 then
    stateData.jumpTimer = util.randomInRange(config.getParameter("flopJumpInterval"))
  end

  return false
end

function flopState.leavingState(stateData)

end
