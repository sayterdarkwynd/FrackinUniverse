miniShoggothSpawnAttack = {}

--------------------------------------------------------------------------------
function miniShoggothSpawnAttack.enter()
  if not hasTarget() then
    return nil
  end

  return {
    timer = config.getParameter("miniShoggothSpawnAttack.skillTime", 8),
    damagePerSecond = config.getParameter("miniShoggothSpawnAttack.damagePerSecond", 10),
    distanceRange = config.getParameter("miniShoggothSpawnAttack.distanceRange"),
    winddownTimer = config.getParameter("miniShoggothSpawnAttack.winddownTime"),
    windupTimer = config.getParameter("miniShoggothSpawnAttack.windupTime"),
    periodTimer = config.getParameter("miniShoggothSpawnAttack.periodTime"),
    attacksLeft = config.getParameter("miniShoggothSpawnAttack.attacksLeft"),
    --initialPeriodTime = periodTimer,
    spitting = false
  }
end

--------------------------------------------------------------------------------
function miniShoggothSpawnAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  monster.setActiveSkillName("miniShoggothSpawnAttack")
end

--------------------------------------------------------------------------------
function miniShoggothSpawnAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])


  if not stateData.spitting then 
    if math.abs(toTarget[1]) > stateData.distanceRange[2] then
      animator.setAnimationState("movement", "walk")
      move(toTarget, false)
    elseif math.abs(toTarget[1]) < stateData.distanceRange[1] then
      move({-toTarget[1], toTarget[2]}, false)
      animator.setAnimationState("movement", "walk")
      mcontroller.controlFace(targetDir)
    else
      stateData.spitting = true
    end
  else
    mcontroller.controlFace(targetDir)
    if stateData.windupTimer > 0 then
      if stateData.windupTimer == config.getParameter("miniShoggothSpawnAttack.windupTime") then
      animator.setAnimationState("movement", "idle2")
      end
      stateData.windupTimer = stateData.windupTimer - dt

    -- additional step here: iterate through three spits first
    elseif stateData.attacksLeft > 0 then
      if stateData.periodTimer < 0 then
        animator.playSound("squish")
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
  local projectileType = config.getParameter("miniShoggothSpawnAttack.projectile.type")
  local projectileConfig = config.getParameter("miniShoggothSpawnAttack.projectile.config")
  local projectileOffset = config.getParameter("miniShoggothSpawnAttack.projectile.offset")
  local direction2 = vec2.add(direction, {0, 10})
  local direction3 = vec2.add(direction, {0, -10})

  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
  end


  world.spawnProjectile(projectileType, monster.toAbsolutePosition(projectileOffset), entity.id(), direction, true, projectileConfig)
end

function miniShoggothSpawnAttack.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  monster.setActiveSkillName("")
end

