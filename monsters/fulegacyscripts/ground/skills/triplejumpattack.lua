tripleJumpAttack = {
  minDistance = 8,
  maxMoveTime = 2,

  windupTime = 0.2,

  hopTime = 0,
  hopMoveTime = 0.1,

  jumpTime = 0.2,
  jumpMoveTime = 1.0,

  maxLandWaitTime = 4,
}

function tripleJumpAttack.enter()
  if not canStartSkill("tripleJumpAttack") then return nil end

  return { run = coroutine.wrap(tripleJumpAttack.run) }
end

function tripleJumpAttack.enteringState(stateData)
  entity.setAnimationState("movement", "idle")
  entity.setAnimationState("attack", "idle")

  entity.setActiveSkillName("tripleJumpAttack")
end

function tripleJumpAttack.update(dt, stateData)
  if not hasTarget() then return true end
  return stateData.run(stateData)
end

function tripleJumpAttack.leavingState(stateData)
end

function tripleJumpAttack.run(stateData)
  local timer = tripleJumpAttack.maxMoveTime
  while timer > 0 and math.abs(self.toTarget[1]) < tripleJumpAttack.minDistance do
    move({ -self.toTarget[1], 0 }, true)
    timer = timer - script.updateDt()
    coroutine.yield(false)
  end

  entity.setAnimationState("movement", "chargeWindup")
  mcontroller.controlFace(self.toTarget[1])
  util.wait(tripleJumpAttack.windupTime)

  tripleJumpAttack.jump(tripleJumpAttack.hopTime, tripleJumpAttack.hopMoveTime, false)
  tripleJumpAttack.jump(tripleJumpAttack.hopTime, tripleJumpAttack.hopMoveTime, false)

  tripleJumpAttack.jump(tripleJumpAttack.jumpTime, tripleJumpAttack.jumpMoveTime, true)

  return true
end

function tripleJumpAttack.jump(jumpTime, moveTime, trackTarget)
  local direction = util.toDirection(self.toTarget[1])
  mcontroller.controlFace(direction)

  entity.setAnimationState("movement", "jump")
  controlJump()
  coroutine.yield(false)

  local jumpTimer = jumpTime
  local moveTimer = moveTime
  util.wait(math.max(jumpTime, moveTime), function(dt)
    if mcontroller.onGround() then return true end

    setAggressive(true, true)

    if jumpTimer > 0 then
      mcontroller.controlHoldJump()
      jumpTimer = jumpTimer - dt
    end

    if moveTimer > 0 then
      moveX(direction, true)
      moveTimer = moveTimer - dt
    end

    if trackTarget then
      direction = util.toDirection(self.toTarget[1])
      mcontroller.controlFace(direction)
    end
  end)

  util.wait(tripleJumpAttack.maxLandWaitTime, function()
    if mcontroller.onGround() then return true end
  end)
end
