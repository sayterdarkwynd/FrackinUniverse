fuPounceAttack = {}

function fuPounceAttack.loadSkillParameters()
  local params = config.getParameter("fuPounceAttack")

  local jumpSpeed = fuPounceAttack.jumpSpeed()
  local maxJumpDistance = 0.8 * ( (jumpSpeed * jumpSpeed * 0.7071) / (world.gravity(mcontroller.position()) * 1.5) )
  local tolerance = {-1, -9.0, 6, 7}

  params.approachPoints = { {-(maxJumpDistance), 3}, {(maxJumpDistance), 3} }
  params.startRects = {}
  for i, point in ipairs(params.approachPoints) do
    if point[1] > 0 then
      params.startRects[i] = {point[1] + tolerance[1], point[2] + tolerance[2], point[1] + tolerance[3], point[2] + tolerance[4]}
    else
      params.startRects[i] = {point[1] - tolerance[3], point[2] + tolerance[2], point[1] - tolerance[1], point[2] + tolerance[4]}
    end
  end

  return params
end

function fuPounceAttack.jumpSpeed()
  return math.min(mcontroller.baseParameters().airJumpProfile.jumpSpeed * config.getParameter("fuPounceAttack.jumpSpeedMultiplier"), config.getParameter("fuPounceAttack.jumpSpeedMax"))
end

function fuPounceAttack.enter()
  if not canStartSkill("fuPounceAttack") then return nil end

  mcontroller.controlFace(self.toTarget[1])

  return {
    winddownTime = 0.0,
    windupTime = config.getParameter("fuPounceAttack.windupTime"),
    followThrough = false
  }
end

function fuPounceAttack.enteringState(stateData)
  animator.setAnimationState("attack", "idle")
  monster.setActiveSkillName("fuPounceAttack")
end

function fuPounceAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  mcontroller.controlParameters({airFriction=0})

  if stateData.windupTime > 0 then
    stateData.windupTime = stateData.windupTime - dt

    animator.setAnimationState("movement", "chargeWindup")
    faceTarget()

  elseif not stateData.followThrough then
    setAggressive(true, true)
    animator.setAnimationState("movement", "jump")

    stateData.pounceJumpHoldTime = config.getParameter("fuPounceAttack.jumpHoldTime")
    stateData.pounceWasOffGround = false
    stateData.followThrough = true

    local jumpSpeed = fuPounceAttack.jumpSpeed()
    stateData.jumpVector = util.aimVector(self.toTarget, jumpSpeed, 1.5, true)
    mcontroller.setVelocity(stateData.jumpVector)
  end

  if stateData.winddownTime > 0.0 then
    animator.setAnimationState("movement", "idle")
    animator.setAnimationState("attack", "idle")
    stateData.winddownTime = stateData.winddownTime - dt
    return stateData.winddownTime <= 0.0
  elseif stateData.followThrough then
    animator.setAnimationState("attack", "charge")

    -- --re-set the velocity until we've properly left the ground to avoid the initial falloff
    if not stateData.pounceWasOffGround then
      mcontroller.setVelocity(stateData.jumpVector)
    end

    -- If the monster is on the ground and was off the ground, the attack is over
    if mcontroller.onGround() then
      if stateData.pounceWasOffGround then
        stateData.winddownTime = config.getParameter("fuPounceAttack.winddownTime")
      end
    else
      stateData.pounceWasOffGround = true
    end
  end

  return false
end

function fuPounceAttack.leavingState(stateData)
end
