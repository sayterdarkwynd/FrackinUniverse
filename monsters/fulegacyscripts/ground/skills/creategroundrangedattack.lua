function createRangedAttack(skillName)
  local rangedAttack = {}

  function rangedAttack.loadSkillParameters()
    local params = config.getParameter(skillName)

    --parameters to be used within this state
    rangedAttack.pType = type(config.getParameter(skillName..".projectile")) == "table" and entity.staticRandomizeParameter(skillName..".projectile") or config.getParameter(skillName..".projectile")
    rangedAttack.pPower = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * params.power
    rangedAttack.pSpeed = params.speed
    rangedAttack.pGrav = root.projectileGravityMultiplier(rangedAttack.pType)
    rangedAttack.pArc = params.arc
    rangedAttack.shots = params.shots or 1.0
    rangedAttack.fireInterval = params.fireInterval or 1
    rangedAttack.range = params.range or 15.0
    rangedAttack.fireAnimation = params.fireAnimation
    rangedAttack.fireAnimationTiming = params.fireAnimationTiming or 0
    rangedAttack.windupTime = params.windupTime or 0.3
    rangedAttack.winddownTime = params.winddownTime or 0.3
    rangedAttack.lockAim = params.lockAim or false

    rangedAttack.castTime = params.castTime or 0
    rangedAttack.castEffect = params.castEffect
    rangedAttack.castAnimation = params.castAnimation

    --parameters to be used by the main script
    params.skillTimeLimit = rangedAttack.castTime + rangedAttack.windupTime + rangedAttack.fireInterval * (rangedAttack.shots - 1) + rangedAttack.winddownTime
    params.cooldownTime = params.cooldownTime or 5.0

    --create geometry
    local yAdjust = -(mcontroller.boundBox()[2] + 2.5) + config.getParameter("projectileSourcePosition", {0, 0})[2]
    params.approachPoints = { {-rangedAttack.range + 3, yAdjust}, {rangedAttack.range - 3, yAdjust} }
    params.startRects = {
      {-rangedAttack.range, -7 + yAdjust, math.min(-rangedAttack.range + 10.5, -1), 5 + yAdjust},
      {math.max(rangedAttack.range - 10.5, 1), -7 + yAdjust, rangedAttack.range, 5 + yAdjust}
    }

    return params
  end

  function rangedAttack.enter()
    if not canStartSkill(skillName) then return nil end

    return { castTime = rangedAttack.castTime, fireCooldown = math.max(rangedAttack.windupTime, rangedAttack.fireAnimationTiming), shotsRemaining = rangedAttack.shots }
  end

  function rangedAttack.enteringState(stateData)
    setAggressive(true, true)

    rangedAttack.aim(world.distance(world.entityPosition(self.target), monster.toAbsolutePosition(config.getParameter("projectileSourcePosition"))))

    if stateData.castTime > 0 then
      if rangedAttack.castEffect then
        status.addEphemeralEffect(rangedAttack.castEffect, rangedAttack.castTime)
      end

      if rangedAttack.castAnimation then
        animator.setAnimationState("attack", rangedAttack.castAnimation)
      end
    end

    monster.setActiveSkillName(skillName)
  end

  function rangedAttack.update(dt, stateData)
    if not canContinueSkill() then return true end

    if stateData.castTime > 0 then
      stateData.castTime = stateData.castTime - dt
      return false
    end

    if stateData.shotsRemaining <= 0 then return false end

    local toTarget = world.distance(world.entityPosition(self.target), monster.toAbsolutePosition(config.getParameter("projectileSourcePosition")))

    if toTarget[1] * mcontroller.facingDirection() < 0 then return true end

    if not rangedAttack.lockAim then rangedAttack.aim(toTarget) end

    if not rangedAttack.fireAnimation then animator.setAnimationState("attack", "shooting") end

    if rangedAttack.fireAnimation and stateData.fireCooldown <= rangedAttack.fireAnimationTiming then
      animator.setAnimationState("attack", rangedAttack.fireAnimation)
    end

    if stateData.fireCooldown <= 0 then
      if not rangedAttack.lockAim or not stateData.fireVector then
        stateData.fireVector = toTarget
        if rangedAttack.pArc ~= nil then
          stateData.fireVector = util.aimVector(toTarget, rangedAttack.pSpeed, rangedAttack.pGrav, rangedAttack.pArc == "high")
        end
      end

      rangedAttack.fire(stateData.fireVector)

      stateData.shotsRemaining = stateData.shotsRemaining - 1
      stateData.fireCooldown = rangedAttack.fireInterval
    end
    stateData.fireCooldown = stateData.fireCooldown - dt

    local movement = calculateSeparationMovement()
    if movement ~= 0 then
      animator.setAnimationState("movement", "walk")

      if movement > 0 then
        moveX(1, true)
      else
        moveX(-1, true)
      end
    else
      animator.setAnimationState("movement", "idle")
    end

    return false
  end

  function rangedAttack.aim(direction)
    animator.rotateGroup("projectileAim", 0)
    mcontroller.controlFace(util.toDirection(direction[1]))

    local maxRotate = math.pi / 180 * 30
    local rotateAmount = math.atan(-direction[2],math.abs(direction[1]))

    if rotateAmount > 0 then
      rotateAmount = math.min(rotateAmount, maxRotate)
    else
      rotateAmount = math.max(rotateAmount, -maxRotate)
    end

    animator.rotateGroup("projectileAim", rotateAmount);
  end

  function rangedAttack.fire(direction)
    local pConfig = {
      power = rangedAttack.pPower,
      speed = rangedAttack.pSpeed
    }
    local sourceOffset = config.getParameter("projectileSourceOffset")
    local sourcePosition = config.getParameter("projectileSourcePosition")
    if sourceOffset then
      local angle = math.atan(direction[2], math.abs(direction[1]))
      sourceOffset = vec2.rotate(sourceOffset, angle)
      sourcePosition = vec2.add(sourcePosition, sourceOffset)
    end

    world.spawnProjectile(rangedAttack.pType, monster.toAbsolutePosition(sourcePosition), entity.id(), direction, false, pConfig)

    animator.playSound("rangedAttack")
  end

  function rangedAttack.leavingState(stateData)
    animator.rotateGroup("projectileAim", 0)
  end

  return rangedAttack
end
