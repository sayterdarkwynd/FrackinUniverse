fleshBombAttack = {}

--------------------------------------------------------------------------------
function fleshBombAttack.enter()
  if not hasTarget() then
    return nil
  end

  return {
    timer = entity.configParameter("fleshBombAttack.skillTime", 16),
    damagePerSecond = entity.configParameter("fleshBombAttack.damagePerSecond", 1600),
    distanceRange = entity.configParameter("fleshBombAttack.distanceRange"),
    winddownTimer = entity.configParameter("fleshBombAttack.winddownTime"),
    windupTimer = entity.configParameter("fleshBombAttack.windupTime"),
    bombing = false
  }
end

--------------------------------------------------------------------------------
function fleshBombAttack.enteringState(stateData)
  entity.setAnimationState("movement", "idle")

  entity.setActiveSkillName("fleshBombAttack")
end

--------------------------------------------------------------------------------
function fleshBombAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])


  if not stateData.bombing then 
    if math.abs(toTarget[1]) > stateData.distanceRange[2] then
      entity.setAnimationState("movement", "walk")
      move(toTarget, false)
    elseif math.abs(toTarget[1]) < stateData.distanceRange[1] then
      move({-toTarget[1], toTarget[2]}, false)
      entity.setAnimationState("movement", "walk")
      mcontroller.controlFace(targetDir)
    else
      stateData.bombing = true
    end
  else
    mcontroller.controlFace(targetDir)
    if stateData.windupTimer > 0 then
      if stateData.windupTimer == entity.configParameter("fleshBombAttack.windupTime") then
      entity.setAnimationState("movement", "idle")
      end
      stateData.windupTimer = stateData.windupTimer - dt
    elseif stateData.winddownTimer > 0 then
      if stateData.winddownTimer == entity.configParameter("fleshBombAttack.winddownTime") then
        fleshBombAttack.bomb(toTarget)
      end
      stateData.winddownTimer = stateData.winddownTimer - dt
    else
      stateData.bombing = false
      return true
    end
  end


  return false
end

function fleshBombAttack.bomb(direction)
  local projectileType = entity.configParameter("fleshBombAttack.projectile.type")
  local projectileConfig = entity.configParameter("fleshBombAttack.projectile.config")
  local projectileOffset = entity.configParameter("fleshBombAttack.projectile.offset")
  local direction2 = vec2.add(direction, {0, 10})
  local direction3 = vec2.add(direction, {0, -10})

  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", entity.level())
  end


  world.spawnProjectile(projectileType, entity.toAbsolutePosition(projectileOffset), entity.id(), direction, true, projectileConfig)
  world.spawnProjectile(projectileType, entity.toAbsolutePosition(projectileOffset), entity.id(), direction2, true, projectileConfig)
end

function fleshBombAttack.leavingState(stateData)
  entity.setAnimationState("movement", "idle")
  entity.setActiveSkillName("")
end

