fuChargeAttack = {}

function fuChargeAttack.enter()
  if not canStartSkill("fuChargeAttack") then return nil end

  -- Don't start a charge attack if we're blocked or about to fall
  if isBlocked() or willFall() then
    return nil
  end

  local fuChargeAttackDirection = self.toTarget[1]
  mcontroller.controlFace(fuChargeAttackDirection)

  return {
    windupTime = entity.configParameter("fuChargeAttack.windupTime"),
    winddownTime = 0,
    fuChargeAttackDirection = fuChargeAttackDirection
  }
end

function fuChargeAttack.enteringState(stateData)
  animator.setAnimationState("attack", "idle")
  setAggressive(true, true)

  entity.setActiveSkillName("fuChargeAttack")
end

function fuChargeAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  mcontroller.controlParameters({runSpeed=mcontroller.baseParameters().runSpeed + entity.configParameter("fuChargeAttack.speedBonus")})

  if stateData.windupTime > 0 then
    stateData.windupTime = stateData.windupTime - dt
    animator.setAnimationState("movement", "chargeWindup")
  elseif stateData.winddownTime > 0 then
    stateData.winddownTime = stateData.winddownTime - dt

    animator.setAnimationState("attack", "idle")
    setAggressive(true, false)

    if isBlocked() then
      animator.setAnimationState("movement", "idle")
    else
      if 2 * stateData.winddownTime > entity.configParameter("fuChargeAttack.winddownTime") / 3 then
        animator.setAnimationState("movement", "charge")
        moveX(stateData.fuChargeAttackDirection, true)
      elseif stateData.winddownTime > entity.configParameter("fuChargeAttack.winddownTime") / 3 then
        animator.setAnimationState("movement", "walk")
        moveX(stateData.fuChargeAttackDirection, true)
      else
        animator.setAnimationState("movement", "idle")
      end
    end

    if stateData.winddownTime <= 0 then
      return true
    end
  else
    moveX(stateData.fuChargeAttackDirection, true)
    animator.setAnimationState("movement", "charge")

    if isBlocked() then
      --CRASH
      entity.playSound("chargeCrash")

      local crashTiles = {}
      local basePos = entity.configParameter("projectileSourcePosition", {0, 0})
      for xOffset = 2, 3 do
        for yOffset = -1, 1 do
          table.insert(crashTiles, object.toAbsolutePosition({basePos[1] + xOffset, basePos[2] + yOffset}))
        end
      end
      world.damageTiles(crashTiles, "foreground", object.toAbsolutePosition({10, 0}), "plantish", entity.configParameter("fuChargeAttack.crashDamageAmount"))

      self.state.pickState({stun=true,duration=entity.configParameter("fuChargeAttack.crashStunTime")})
      return true
    end

    if entity.animationState("attack") ~= "fuChargeAttack" then
      if math.abs(self.toTarget[1]) < entity.configParameter("fuChargeAttack.attackDistance") then
        animator.setAnimationState("attack", "charge")
      elseif self.toTarget[1] * mcontroller.facingDirection() > 0 then
        animator.setAnimationState("attack", "charge")
      else
        stateData.winddownTime = entity.configParameter("fuChargeAttack.winddownTime")
      end
    else
      if math.abs(self.toTarget[1]) > entity.configParameter("fuChargeAttack.attackDistance") then
        stateData.winddownTime = entity.configParameter("fuChargeAttack.winddownTime")
      end
    end
  end

  return false
end

function fuChargeAttack.leavingState(stateData)
end
