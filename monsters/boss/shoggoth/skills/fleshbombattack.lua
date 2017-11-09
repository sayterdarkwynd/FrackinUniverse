fleshBombAttack = {}

--------------------------------------------------------------------------------
function fleshBombAttack.enter()
  if not hasTarget() then
    return nil
  end

  return {
    timer = config.getParameter("fleshBombAttack.skillTime", 16),
    damagePerSecond = config.getParameter("fleshBombAttack.damagePerSecond", 1600),
    distanceRange = config.getParameter("fleshBombAttack.distanceRange"),
    winddownTimer = config.getParameter("fleshBombAttack.winddownTime"),
    windupTimer = config.getParameter("fleshBombAttack.windupTime"),
    bombing = false
  }
end

--------------------------------------------------------------------------------
function fleshBombAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")

  monster.setActiveSkillName("fleshBombAttack")
end

--------------------------------------------------------------------------------
function fleshBombAttack.update(dt, stateData)
  if not hasTarget() then return true end

  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])


  if not stateData.bombing then 
    if math.abs(toTarget[1]) > stateData.distanceRange[2] then
      animator.setAnimationState("movement", "walk")
      move(toTarget, false)
    elseif math.abs(toTarget[1]) < stateData.distanceRange[1] then
      move({-toTarget[1], toTarget[2]}, false)
      animator.setAnimationState("movement", "walk")
      mcontroller.controlFace(targetDir)
    else
      stateData.bombing = true
    end
  else
    mcontroller.controlFace(targetDir)
    if stateData.windupTimer > 0 then
      if stateData.windupTimer == config.getParameter("fleshBombAttack.windupTime") then
      animator.setAnimationState("movement", "idle4")
      
      self.randValNum = math.random(100)
      if self.randValNum >=50 then
        animator.playSound("attackMain")
      end      
	  animator.setParticleEmitterOffsetRegion("chargeUp", mcontroller.boundBox())
	  animator.setParticleEmitterActive("chargeUp", true)       
      end
      stateData.windupTimer = stateData.windupTimer - dt
    elseif stateData.winddownTimer > 0 then
      if stateData.winddownTimer == config.getParameter("fleshBombAttack.winddownTime") then
        animator.playSound("fleshBomb")
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
  local projectileType = config.getParameter("fleshBombAttack.projectile.type")
  local projectileConfig = config.getParameter("fleshBombAttack.projectile.config")
  local projectileOffset = config.getParameter("fleshBombAttack.projectile.offset")
  local direction2 = vec2.add(direction, {0, 10})
  local direction3 = vec2.add(direction, {0, -10})

  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
  end


  world.spawnProjectile(projectileType, monster.toAbsolutePosition(projectileOffset), entity.id(), direction, true, projectileConfig)
  world.spawnProjectile(projectileType, monster.toAbsolutePosition(projectileOffset), entity.id(), direction2, true, projectileConfig)
end

function fleshBombAttack.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  monster.setActiveSkillName("")
end

