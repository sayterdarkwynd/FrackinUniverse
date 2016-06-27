miniShoggothSpawnAttack = {}

--------------------------------------------------------------------------------
function miniShoggothSpawnAttack.enter()
  if not hasTarget() then
    return nil
  end

  return {
    timer = entity.configParameter("miniShoggothSpawnAttack.skillTime", 16),
    damagePerSecond = entity.configParameter("miniShoggothSpawnAttack.damagePerSecond", 1600),
    distanceRange = entity.configParameter("miniShoggothSpawnAttack.distanceRange"),
    winddownTimer = entity.configParameter("miniShoggothSpawnAttack.winddownTime"),
    windupTimer = entity.configParameter("miniShoggothSpawnAttack.windupTime"),
    periodTimer = entity.configParameter("miniShoggothSpawnAttack.periodTime"),
    attacksLeft = entity.configParameter("miniShoggothSpawnAttack.attacksLeft"),
    --initialPeriodTime = periodTimer,
    spitting = false
  }
end

--------------------------------------------------------------------------------
function miniShoggothSpawnAttack.enteringState(stateData)
  entity.setAnimationState("movement", "idle")
  entity.setActiveSkillName("miniShoggothSpawnAttack")
end

--------------------------------------------------------------------------------
function miniShoggothSpawnAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])


  if not stateData.spitting then 
    if math.abs(toTarget[1]) > stateData.distanceRange[2] then
      entity.setAnimationState("movement", "walk")
      move(toTarget, false)
    elseif math.abs(toTarget[1]) < stateData.distanceRange[1] then
      move({-toTarget[1], toTarget[2]}, false)
      entity.setAnimationState("movement", "walk")
      mcontroller.controlFace(targetDir)
    else
      stateData.spitting = true
    end
  else
    mcontroller.controlFace(targetDir)
    if stateData.windupTimer > 0 then
      if stateData.windupTimer == entity.configParameter("miniShoggothSpawnAttack.windupTime") then
      entity.setAnimationState("movement", "idle")
      end
      stateData.windupTimer = stateData.windupTimer - dt

    -- additional step here: iterate through three spits first
    elseif stateData.attacksLeft > 0 then
      if stateData.periodTimer < 0 then
        miniShoggothSpawnAttack.spit(toTarget)
        stateData.periodTimer = 1
        stateData.attacksLeft = stateData.attacksLeft - 1
      else
        stateData.periodTimer = stateData.periodTimer - dt
      end

    --- finished all attacks
    elseif stateData.winddownTimer > 0 then

      stateData.winddownTimer = stateData.winddownTimer - dt
    else
      stateData.spitting = false
      return true
    end
  end


  return false
end

function miniShoggothSpawnAttack.spit(direction)
  local projectileType = entity.configParameter("miniShoggothSpawnAttack.projectile.type")
  local projectileConfig = entity.configParameter("miniShoggothSpawnAttack.projectile.config")
  local projectileOffset = entity.configParameter("miniShoggothSpawnAttack.projectile.offset")
  local direction2 = vec2.add(direction, {0, 10})
  local direction3 = vec2.add(direction, {0, -10})

  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", entity.level())
  end


  world.spawnProjectile(projectileType, entity.toAbsolutePosition(projectileOffset), entity.id(), direction, true, projectileConfig)
end

function miniShoggothSpawnAttack.leavingState(stateData)
  entity.setAnimationState("movement", "idle")
  entity.setActiveSkillName("")
end

