--------------------------------------------------------------------------------
dollfaceTransitionAttack = {}

function dollfaceTransitionAttack.enterWith(args)
  if not args or not args.enteringPhase then return nil end
  if not hasTarget() then return nil end

  rangedAttack.setConfig(config.getParameter("dollfaceTransitionAttack.projectile.type"), config.getParameter("dollfaceTransitionAttack.projectile.config"), config.getParameter("dollfaceTransitionAttack.fireInterval"))

  return {
    timer = 0,
    skillTime = config.getParameter("dollfaceTransitionAttack.skillTime")
  }
end

function dollfaceTransitionAttack.enteringState(stateData)
  monster.setActiveSkillName("dollfaceTransitionAttack")
end

function dollfaceTransitionAttack.update(dt, stateData)
  mcontroller.controlFace(1)
  if not hasTarget() then return true end

  if stateData.timer==0 and animator.animationState("head") ~= "scream" then
    animator.setAnimationState("head", "screamwindup", false)
    if animator.animationState("head") == "screamwindup" then return false end
  end

  if animator.animationState("head")=="scream" then
    if stateData.timer==0 then animator.playSound("scream") end
    local projectileOffset = config.getParameter("dollfaceTransitionAttack.projectileOffset")
    local aimAngle = math.random() * (math.pi - -math.pi) + -math.pi
    local aimvec = vec2.withAngle(aimAngle, 1.0)
    local toTarget = vec2.norm(vec2.withAngle(aimAngle, 1.0), monster.toAbsolutePosition(projectileOffset))
    rangedAttack.aim(projectileOffset, toTarget)
    rangedAttack.fireContinuous()
    stateData.timer = stateData.timer + dt
  end

  if stateData.timer > stateData.skillTime then
    if animator.animationState("head") == "scream" then animator.setAnimationState("head", "screamwinddown", false) end
    return animator.animationState("head") == "idle"
  else
    return false
  end
end

function dollfaceTransitionAttack.leavingState(stateData)
  rangedAttack.stopFiring()
end
