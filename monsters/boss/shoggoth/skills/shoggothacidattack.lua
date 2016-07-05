shoggothAcidAttack = {}

--------------------------------------------------------------------------------
function shoggothAcidAttack.enter()
  if not hasTarget() then
    return nil
  end

  return {
    timer = entity.configParameter("shoggothAcidAttack.skillTime", 16),
    damagePerSecond = entity.configParameter("shoggothAcidAttack.damagePerSecond", 1600),
    distanceRange = entity.configParameter("shoggothAcidAttack.distanceRange"),
    winddownTimer = entity.configParameter("shoggothAcidAttack.winddownTime"),
    windupTimer = entity.configParameter("shoggothAcidAttack.windupTime"),
    periodTimer = entity.configParameter("shoggothAcidAttack.periodTime"),
    attacksLeft = entity.configParameter("shoggothAcidAttack.attacksLeft"),
    --initialPeriodTime = periodTimer,
    spitting = false
  }
end

--------------------------------------------------------------------------------
function shoggothAcidAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  entity.setActiveSkillName("shoggothAcidAttack")
end

--------------------------------------------------------------------------------
function shoggothAcidAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])
  if (targetDir == 1) then 
    toTarget = world.distance(self.targetPosition, vec2.add(mcontroller.position(), {10, -5}))
  else
    toTarget = world.distance(self.targetPosition, vec2.add(mcontroller.position(), {-10, -5}))
  end

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
      if stateData.windupTimer == entity.configParameter("shoggothAcidAttack.windupTime") then
      animator.setAnimationState("movement", "idle")
      end
      stateData.windupTimer = stateData.windupTimer - dt

    -- additional step here: iterate through three spits first
    elseif stateData.attacksLeft > 0 then
      if stateData.periodTimer < 0 then
        shoggothAcidAttack.spit(toTarget)
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

function shoggothAcidAttack.spit(direction)
  local projectileType = entity.configParameter("shoggothAcidAttack.projectile.type")
  local projectileConfig = entity.configParameter("shoggothAcidAttack.projectile.config")
  local projectileOffset = entity.configParameter("shoggothAcidAttack.projectile.offset")
  local direction2 = vec2.add(direction, {0, 10})
  local direction3 = vec2.add(direction, {0, -10})

  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", entity.level())
  end


  world.spawnProjectile(projectileType, object.toAbsolutePosition(projectileOffset), entity.id(), direction, true, projectileConfig)
end

function shoggothAcidAttack.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  entity.setActiveSkillName("")
end

