fumechspiderAttack = {}

--allow force entering state without canStartSkill
function fumechspiderAttack.enterWith(args)
  if not args.fumechspiderAttack then return nil end

  return { 
    didAttack = false, 
    wasInRange = false,
    windupTimer = entity.configParameter("fumechspiderAttack.windupTime"),
    winddownTimer = entity.configParameter("fumechspiderAttack.windDownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fumechspiderAttack.enter()
  if not canStartSkill("fumechspiderAttack") then return nil end

  return { 
    didAttack = false, 
    wasInRange = false,
    windupTimer = entity.configParameter("fumechspiderAttack.windupTime"),
    winddownTimer = entity.configParameter("fumechspiderAttack.winddownTime"),
    fireTimer = 0,
    shots = 0
  }
end

function fumechspiderAttack.enteringState(stateData)
  setAggressive(true, false)
  animator.setAnimationState("attack", "melee")

  stateData.projectileSourcePosition = {
      entity.configParameter("projectileSourcePosition", {0, 0})[1],
      entity.configParameter("projectileSourcePosition", {0, 0})[2]
    }

  entity.setActiveSkillName("fumechspiderAttack")
end

function fumechspiderAttack.update(dt, stateData)
  if not canContinueSkill() or not hasTarget() then return true end

  local targetPosition = world.entityPosition(self.target)
  local toTarget = world.distance(targetPosition, mcontroller.position())

  local projectileName = entity.configParameter("fumechspiderAttack.projectile")
  local power = root.evalFunction("monsterLevelPowerMultiplier", entity.level()) * entity.configParameter("fumechspiderAttack.power")

  animator.setAnimationState("movement", "idle")

  --First wind up
  if stateData.windupTimer >= 0 then
    if stateData.windupTimer == entity.configParameter("fumechspiderAttack.windupTime") then
      animator.setAnimationState("attack", "windup")
    end

    stateData.windupTimer = stateData.windupTimer - dt
  --Then fire all projectiles
  elseif stateData.shots < entity.configParameter("fumechspiderAttack.shots") then
    if stateData.fireTimer <= 0 then
      world.spawnProjectile(projectileName, object.toAbsolutePosition(stateData.projectileSourcePosition), entity.id(), {mcontroller.facingDirection(), 0}, false, {power = power})
      stateData.shots = stateData.shots + 1
      stateData.fireTimer = stateData.fireTimer + entity.configParameter("fumechspiderAttack.fireInterval")
    end

    stateData.fireTimer = stateData.fireTimer - dt
  --Then wind down
  elseif stateData.winddownTimer >= 0 then
    if stateData.winddownTimer == entity.configParameter("fumechspiderAttack.winddownTime") then
      animator.setAnimationState("attack", "winddown")
    end

    stateData.winddownTimer = stateData.winddownTimer - dt
  --Then done
  else
    return true, entity.configParameter("fumechspiderAttack.cooldownTime")
  end

  return false
end

function fumechspiderAttack.leavingState(stateData)
  
end
