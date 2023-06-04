fuspiderwalkerAttack = {}

--allow force entering state without canStartSkill
function fuspiderwalkerAttack.enterWith(args)
  if not args.fuspiderwalkerAttack then return nil end

  return {
    didAttack = false,
    wasInRange = false,
    windupTimer = config.getParameter("fuspiderwalkerAttack.windupTime"),
    winddownTimer = config.getParameter("fuspiderwalkerAttack.windDownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fuspiderwalkerAttack.enter()
  if not canStartSkill("fuspiderwalkerAttack") then return nil end

  return {
    didAttack = false,
    wasInRange = false,
    windupTimer = config.getParameter("fuspiderwalkerAttack.windupTime"),
    winddownTimer = config.getParameter("fuspiderwalkerAttack.winddownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fuspiderwalkerAttack.enteringState(stateData)
  setAggressive(true, false)
  animator.setAnimationState("attack", "melee")

  stateData.projectileSourcePosition = {
      config.getParameter("projectileSourcePosition", {0, 0})[1],
      config.getParameter("projectileSourcePosition", {0, 0})[2]
    }

  monster.setActiveSkillName("fuspiderwalkerAttack")
end

function fuspiderwalkerAttack.update(dt, stateData)
  if not canContinueSkill() or not hasTarget() then return true end

  local projectileName = config.getParameter("fuspiderwalkerAttack.projectile")
  local power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * config.getParameter("fuspiderwalkerAttack.power")

  animator.setAnimationState("movement", "idle")

  --First wind up
  if stateData.windupTimer >= 0 then
    if stateData.windupTimer == config.getParameter("fuspiderwalkerAttack.windupTime") then
      animator.setAnimationState("attack", "windup")
    end

    stateData.windupTimer = stateData.windupTimer - dt
  --Then fire all projectiles
  elseif stateData.shots < config.getParameter("fuspiderwalkerAttack.shots") then
    if stateData.fireTimer <= 0 then
      world.spawnProjectile(projectileName, monster.toAbsolutePosition(stateData.projectileSourcePosition), entity.id(), {mcontroller.facingDirection(), 0}, false, {power = power})
      stateData.shots = stateData.shots + 1
      stateData.fireTimer = stateData.fireTimer + config.getParameter("fuspiderwalkerAttack.fireInterval")
    end

    stateData.fireTimer = stateData.fireTimer - dt
  --Then wind down
  elseif stateData.winddownTimer >= 0 then
    if stateData.winddownTimer == config.getParameter("fuspiderwalkerAttack.winddownTime") then
      animator.setAnimationState("attack", "winddown")
    end

    stateData.winddownTimer = stateData.winddownTimer - dt
  --Then done
  else
    return true, config.getParameter("fuspiderwalkerAttack.cooldownTime")
  end

  return false
end

function fuspiderwalkerAttack.leavingState(stateData)

end
