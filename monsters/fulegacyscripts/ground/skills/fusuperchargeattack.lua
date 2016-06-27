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
    windupTime = entity.configParameter("fuSuperChargeAttack.windupTime"),
    winddownTime = 0,
    fuSuperChargeAttackDirection = fuSuperChargeAttackDirection
  }
end

function fuSuperChargeAttack.enteringState(stateData)
  entity.setAnimationState("attack", "idle")
  setAggressive(true, true)

  entity.setActiveSkillName("fuSuperChargeAttack")
end

function fuSuperChargeAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  mcontroller.controlParameters({runSpeed=mcontroller.baseParameters().runSpeed + entity.configParameter("fuSuperChargeAttack.speedBonus")})

  if stateData.windupTime > 0 then
    stateData.windupTime = stateData.windupTime - dt
    entity.setAnimationState("movement", "chargeWindup")
  elseif stateData.winddownTime > 0 then
    stateData.winddownTime = stateData.winddownTime - dt

    entity.setAnimationState("attack", "idle")
    setAggressive(true, false)

    if isBlocked() then
      entity.setAnimationState("movement", "idle")
    else
      if 2 * stateData.winddownTime > entity.configParameter("fuSuperChargeAttack.winddownTime") / 3 then
        entity.setAnimationState("movement", "charge")
        moveX(stateData.fuSuperChargeAttackDirection, true)
      elseif stateData.winddownTime > entity.configParameter("fuSuperChargeAttack.winddownTime") / 3 then
        entity.setAnimationState("movement", "walk")
        moveX(stateData.fuSuperChargeAttackDirection, true)
      else
        entity.setAnimationState("movement", "idle")
      end
    end

    if stateData.winddownTime <= 0 then
      return true
    end
  else
    moveX(stateData.fuSuperChargeAttackDirection, true)
    entity.setAnimationState("movement", "charge")

    if isBlocked() then
      --CRASH
      entity.playSound("chargeCrash")

      local crashTiles = {}
      local basePos = entity.configParameter("projectileSourcePosition", {0, 0})
      for xOffset = 2, 3 do
        for yOffset = -1, 1 do
          table.insert(crashTiles, entity.toAbsolutePosition({basePos[1] + xOffset, basePos[2] + yOffset}))
        end
      end
      world.damageTiles(crashTiles, "foreground", entity.toAbsolutePosition({10, 0}), "plantish", entity.configParameter("fuSuperChargeAttack.crashDamageAmount"))

      self.state.pickState({stun=true,duration=entity.configParameter("fuSuperChargeAttack.crashStunTime")})
      return true
    end

    if entity.animationState("attack") ~= "fuSuperChargeAttack" then
      if math.abs(self.toTarget[1]) < entity.configParameter("fuSuperChargeAttack.attackDistance") then
        entity.setAnimationState("attack", "charge")
      elseif self.toTarget[1] * mcontroller.facingDirection() > 0 then
        entity.setAnimationState("attack", "charge")
      else
        stateData.winddownTime = entity.configParameter("fuSuperChargeAttack.winddownTime")
      end
    else
      if math.abs(self.toTarget[1]) > entity.configParameter("fuSuperChargeAttack.attackDistance") then
        stateData.winddownTime = entity.configParameter("fuSuperChargeAttack.winddownTime")
      end
    end
  end

  return false
end

function fuSuperChargeAttack.leavingState(stateData)
end
