tentacleSwipeAttack = {}

--------------------------------------------------------------------------------
function tentacleSwipeAttack.enter()
  if not hasTarget() then
    return nil
  end
  monster.setDamageOnTouch(true)


  return {
    timer = config.getParameter("tentacleSwipeAttack.skillTime", 16),
    damagePerSecond = config.getParameter("tentacleSwipeAttack.damagePerSecond", 1600),
    distanceRange = config.getParameter("tentacleSwipeAttack.distanceRange"),
    winddownTimer = config.getParameter("tentacleSwipeAttack.winddownTime"),
    windupTimer = config.getParameter("tentacleSwipeAttack.windupTime"),
    swiping = false
  }
end

--------------------------------------------------------------------------------
function tentacleSwipeAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")

  monster.setActiveSkillName("tentacleSwipeAttack")
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
      if stateData.windupTimer == config.getParameter("tentacleSwipeAttack.windupTime") then
      	animator.setAnimationState("movement", "swipe") 
      	
      self.randValNum = math.random(100)
      if self.randValNum >=75 then
        animator.playSound("attackMain")
      end      	
	  animator.setParticleEmitterOffsetRegion("whipUp", mcontroller.boundBox())
	  animator.setParticleEmitterActive("whipUp", true)       	
      end
      stateData.windupTimer = stateData.windupTimer - dt
    elseif stateData.winddownTimer > 0 then
      if stateData.winddownTimer == config.getParameter("tentacleSwipeAttack.winddownTime") then
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
  local projectileType = config.getParameter("tentacleSwipeAttack.projectile.type")
  local projectileConfig = config.getParameter("tentacleSwipeAttack.projectile.config")
  local projectileOffset = config.getParameter("tentacleSwipeAttack.projectile.offset")
  
  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
  end

  world.spawnProjectile(projectileType, monster.toAbsolutePosition(projectileOffset), entity.id(), {direction, 0}, true, projectileConfig)
end

function tentacleSwipeAttack.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  monster.setActiveSkillName("")
end

