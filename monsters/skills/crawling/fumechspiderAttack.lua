fumechspiderAttack = {}

--allow force entering state without canStartSkill
function fumechspiderAttack.enterWith(args)
  if not args.fumechspiderAttack then return nil end

  return {
    didAttack = false,
    wasInRange = false,
    windupTimer = config.getParameter("fumechspiderAttack.windupTime"),
    winddownTimer = config.getParameter("fumechspiderAttack.windDownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fumechspiderAttack.enter()
  if not canStartSkill("fumechspiderAttack") then return nil end

  return {
    didAttack = false,
    wasInRange = false,
    windupTimer = config.getParameter("fumechspiderAttack.windupTime"),
    winddownTimer = config.getParameter("fumechspiderAttack.winddownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fumechspiderAttack.enteringState(stateData)
  setAggressive(true, false)
  animator.setAnimationState("attack", "melee")

  stateData.projectileSourcePosition = {
      config.getParameter("projectileSourcePosition", {0, 0})[1],
      config.getParameter("projectileSourcePosition", {0, 0})[2]
    }

  monster.setActiveSkillName("fumechspiderAttack")
end

function fumechspiderAttack.update(dt, stateData)
  if not canContinueSkill() or not hasTarget() then return true end

  local projectileName = config.getParameter("fumechspiderAttack.projectile")
  local power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * config.getParameter("fumechspiderAttack.power")

  animator.setAnimationState("movement", "idle")

  --First wind up
  if stateData.windupTimer >= 0 then
    if stateData.windupTimer == config.getParameter("fumechspiderAttack.windupTime") then
      animator.setAnimationState("attack", "windup")
    end

    stateData.windupTimer = stateData.windupTimer - dt
  --Then fire all projectiles
  elseif stateData.shots < config.getParameter("fumechspiderAttack.shots") then
    if stateData.fireTimer <= 0 then
      world.spawnProjectile(projectileName, monster.toAbsolutePosition(stateData.projectileSourcePosition), entity.id(), {mcontroller.facingDirection(), 0}, false, {power = power})
      stateData.shots = stateData.shots + 1
      stateData.fireTimer = stateData.fireTimer + config.getParameter("fumechspiderAttack.fireInterval")
    end

    stateData.fireTimer = stateData.fireTimer - dt
  --Then wind down
  elseif stateData.winddownTimer >= 0 then
    if stateData.winddownTimer == config.getParameter("fumechspiderAttack.winddownTime") then
      animator.setAnimationState("attack", "winddown")
    end

    stateData.winddownTimer = stateData.winddownTimer - dt
  --Then done
  else
    return true, config.getParameter("fumechspiderAttack.cooldownTime")
  end

  return false
end

function fumechspiderAttack.leavingState(stateData)

end
