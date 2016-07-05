tentacleSwipeAttack = {}

--------------------------------------------------------------------------------
function tentacleSwipeAttack.enter()
  if not hasTarget() then
    return nil
  end
  entity.setDamageOnTouch(true)


  return {
    timer = entity.configParameter("tentacleSwipeAttack.skillTime", 16),
    damagePerSecond = entity.configParameter("tentacleSwipeAttack.damagePerSecond", 1600),
    distanceRange = entity.configParameter("tentacleSwipeAttack.distanceRange"),
    winddownTimer = entity.configParameter("tentacleSwipeAttack.winddownTime"),
    windupTimer = entity.configParameter("tentacleSwipeAttack.windupTime"),
    swiping = false
  }
end

--------------------------------------------------------------------------------
function tentacleSwipeAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")

  entity.setActiveSkillName("tentacleSwipeAttack")
end

--------------------------------------------------------------------------------
function tentacleSwipeAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])

  if not stateData.swiping then 
    if math.abs(toTarget[1]) > stateData.distanceRange[2] then
      animator.setAnimationState("movement", "walk")
      move(toTarget, false)
    elseif math.abs(toTarget[1]) < stateData.distanceRange[1] then
      move({-toTarget[1], toTarget[2]}, false)
      animator.setAnimationState("movement", "walk")
      mcontroller.controlFace(targetDir)
    else
      stateData.swiping = true
    end
  else
    mcontroller.controlFace(targetDir)
    if stateData.windupTimer > 0 then
      if stateData.windupTimer == entity.configParameter("tentacleSwipeAttack.windupTime") then
      	animator.setAnimationState("movement", "swipe")
      end
      stateData.windupTimer = stateData.windupTimer - dt
    elseif stateData.winddownTimer > 0 then
      if stateData.winddownTimer == entity.configParameter("tentacleSwipeAttack.winddownTime") then
        tentacleSwipeAttack.swipe(targetDir)
      end
      stateData.winddownTimer = stateData.winddownTimer - dt
    else
      stateData.swiping = false
      return true
    end
  end


  return false
end

function tentacleSwipeAttack.swipe(direction)
  local projectileType = entity.configParameter("tentacleSwipeAttack.projectile.type")
  local projectileConfig = entity.configParameter("tentacleSwipeAttack.projectile.config")
  local projectileOffset = entity.configParameter("tentacleSwipeAttack.projectile.offset")
  
  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", entity.level())
  end

  world.spawnProjectile(projectileType, object.toAbsolutePosition(projectileOffset), entity.id(), {direction, 0}, true, projectileConfig)
end

function tentacleSwipeAttack.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  entity.setActiveSkillName("")
end

