fuspiderwalkerAttack = {}

--allow force entering state without canStartSkill
function fuspiderwalkerAttack.enterWith(args)
  if not args.fuspiderwalkerAttack then return nil end

  return { 
    didAttack = false, 
    wasInRange = false,
    windupTimer = entity.configParameter("fuspiderwalkerAttack.windupTime"),
    winddownTimer = entity.configParameter("fuspiderwalkerAttack.windDownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fuspiderwalkerAttack.enter()
  if not canStartSkill("fuspiderwalkerAttack") then return nil end

  return { 
    didAttack = false, 
    wasInRange = false,
    windupTimer = entity.configParameter("fuspiderwalkerAttack.windupTime"),
    winddownTimer = entity.configParameter("fuspiderwalkerAttack.winddownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fuspiderwalkerAttack.enteringState(stateData)
  setAggressive(true, false)
  entity.setAnimationState("attack", "melee")

  stateData.projectileSourcePosition = {
      entity.configParameter("projectileSourcePosition", {0, 0})[1],
      entity.configParameter("projectileSourcePosition", {0, 0})[2]
    }

  entity.setActiveSkillName("fuspiderwalkerAttack")
end

function fuspiderwalkerAttack.update(dt, stateData)
  if not canContinueSkill() or not hasTarget() then return true end

  local targetPosition = world.entityPosition(self.target)
  local toTarget = world.distance(targetPosition, mcontroller.position())

  local projectileName = entity.configParameter("fuspiderwalkerAttack.projectile")
  local power = root.evalFunction("monsterLevelPowerMultiplier", entity.level()) * entity.configParameter("fuspiderwalkerAttack.power")

  entity.setAnimationState("movement", "idle")

  --First wind up
  if stateData.windupTimer >= 0 then
    if stateData.windupTimer == entity.configParameter("fuspiderwalkerAttack.windupTime") then
      entity.setAnimationState("attack", "windup")
    end

    stateData.windupTimer = stateData.windupTimer - dt
  --Then fire all projectiles
  elseif stateData.shots < entity.configParameter("fuspiderwalkerAttack.shots") then
    if stateData.fireTimer <= 0 then
      world.spawnProjectile(projectileName, entity.toAbsolutePosition(stateData.projectileSourcePosition), entity.id(), {mcontroller.facingDirection(), 0}, false, {power = power})
      stateData.shots = stateData.shots + 1
      stateData.fireTimer = stateData.fireTimer + entity.configParameter("fuspiderwalkerAttack.fireInterval")
    end

    stateData.fireTimer = stateData.fireTimer - dt
  --Then wind down
  elseif stateData.winddownTimer >= 0 then
    if stateData.winddownTimer == entity.configParameter("fuspiderwalkerAttack.winddownTime") then
      entity.setAnimationState("attack", "winddown")
    end

    stateData.winddownTimer = stateData.winddownTimer - dt
  --Then done
  else
    return true, entity.configParameter("fuspiderwalkerAttack.cooldownTime")
  end

  return false
end

function fuspiderwalkerAttack.leavingState(stateData)
  
end
