fuSuperChargeAttack = {}

function fuSuperChargeAttack.enter()
  if not canStartSkill("fuSuperChargeAttack") then return nil end

  -- Don't start a charge attack if we're blocked or about to fall
  if isBlocked() or willFall() then
    return nil
  end

  local fuSuperChargeAttackDirection = self.toTarget[1]
  mcontroller.controlFace(fuSuperChargeAttackDirection)

  return {
    windupTime = config.getParameter("fuSuperChargeAttack.windupTime"),
    winddownTime = 0,
    fuSuperChargeAttackDirection = fuSuperChargeAttackDirection
  }
end

function fuSuperChargeAttack.enteringState(stateData)
  animator.setAnimationState("attack", "idle")
  setAggressive(true, true)

  monster.setActiveSkillName("fuSuperChargeAttack")
end

function fuSuperChargeAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  mcontroller.controlParameters({runSpeed=mcontroller.baseParameters().runSpeed + config.getParameter("fuSuperChargeAttack.speedBonus")})

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
      if 2 * stateData.winddownTime > config.getParameter("fuSuperChargeAttack.winddownTime") / 3 then
        animator.setAnimationState("movement", "charge")
        moveX(stateData.fuSuperChargeAttackDirection, true)
      elseif stateData.winddownTime > config.getParameter("fuSuperChargeAttack.winddownTime") / 3 then
        animator.setAnimationState("movement", "walk")
        moveX(stateData.fuSuperChargeAttackDirection, true)
      else
        animator.setAnimationState("movement", "idle")
      end
    end

    if stateData.winddownTime <= 0 then
      return true
    end
  else
    moveX(stateData.fuSuperChargeAttackDirection, true)
    animator.setAnimationState("movement", "charge")

    if isBlocked() then
      --CRASH
      animator.playSound("chargeCrash")

      local crashTiles = {}
      local basePos = config.getParameter("projectileSourcePosition", {0, 0})
      for xOffset = 2, 3 do
        for yOffset = -1, 1 do
          table.insert(crashTiles, monster.toAbsolutePosition({basePos[1] + xOffset, basePos[2] + yOffset}))
        end
      end
      world.damageTiles(crashTiles, "foreground", monster.toAbsolutePosition({10, 0}), "plantish", config.getParameter("fuSuperChargeAttack.crashDamageAmount"))

      self.state.pickState({stun=true,duration=config.getParameter("fuSuperChargeAttack.crashStunTime")})
      return true
    end

    if animator.animationState("attack") ~= "fuSuperChargeAttack" then
      if math.abs(self.toTarget[1]) < config.getParameter("fuSuperChargeAttack.attackDistance") then
        animator.setAnimationState("attack", "charge")
      elseif self.toTarget[1] * mcontroller.facingDirection() > 0 then
        animator.setAnimationState("attack", "charge")
      else
        stateData.winddownTime = config.getParameter("fuSuperChargeAttack.winddownTime")
      end
    else
      if math.abs(self.toTarget[1]) > config.getParameter("fuSuperChargeAttack.attackDistance") then
        stateData.winddownTime = config.getParameter("fuSuperChargeAttack.winddownTime")
      end
    end
  end

  return false
end

function fuSuperChargeAttack.leavingState(stateData)
end
