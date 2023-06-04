fuFlameThrowerAttack = {}

--allow force entering state without canStartSkill
function fuFlameThrowerAttack.enterWith(args)
  if not args.fuFlameThrowerAttack then return nil end

  return {
    didAttack = false,
    wasInRange = false,
    windupTimer = config.getParameter("fuFlameThrowerAttack.windupTime"),
    winddownTimer = config.getParameter("fuFlameThrowerAttack.windDownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fuFlameThrowerAttack.enter()
  if not canStartSkill("fuFlameThrowerAttack") then return nil end

  return {
    didAttack = false,
    wasInRange = false,
    windupTimer = config.getParameter("fuFlameThrowerAttack.windupTime"),
    winddownTimer = config.getParameter("fuFlameThrowerAttack.winddownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fuFlameThrowerAttack.enteringState(stateData)
  setAggressive(true, false)
  animator.setAnimationState("attack", "melee")

  stateData.projectileSourcePosition = {
      config.getParameter("projectileSourcePosition", {0, 0})[1],
      config.getParameter("projectileSourcePosition", {0, 0})[2]
    }

  monster.setActiveSkillName("fuFlameThrowerAttack")
end

function fuFlameThrowerAttack.update(dt, stateData)
  if not canContinueSkill() or not hasTarget() then return true end

  local targetPosition = world.entityPosition(self.target)
  local toTarget = world.distance(targetPosition, mcontroller.position())

  local projectileName = config.getParameter("fuFlameThrowerAttack.projectile")
  local power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * config.getParameter("fuFlameThrowerAttack.power")

  animator.setAnimationState("movement", "idle")

  --First wind up
  if stateData.windupTimer >= 0 then
    if stateData.windupTimer == config.getParameter("fuFlameThrowerAttack.windupTime") then
      animator.setAnimationState("attack", "windup")
    end

    stateData.windupTimer = stateData.windupTimer - dt
  --Then fire all projectiles
  elseif stateData.shots < config.getParameter("fuFlameThrowerAttack.shots") then
    if stateData.fireTimer <= 0 then
      world.spawnProjectile(projectileName, monster.toAbsolutePosition(stateData.projectileSourcePosition), entity.id(), {mcontroller.facingDirection(), 0}, false, {power = power})
      stateData.shots = stateData.shots + 1
      stateData.fireTimer = stateData.fireTimer + config.getParameter("fuFlameThrowerAttack.fireInterval")
    end

    stateData.fireTimer = stateData.fireTimer - dt
  --Then wind down
  elseif stateData.winddownTimer >= 0 then
    if stateData.winddownTimer == config.getParameter("fuFlameThrowerAttack.winddownTime") then
      animator.setAnimationState("attack", "winddown")
    end

    stateData.winddownTimer = stateData.winddownTimer - dt
  --Then done
  else
    return true, config.getParameter("fuFlameThrowerAttack.cooldownTime")
  end

  return false
end

function fuFlameThrowerAttack.leavingState(stateData)

end
