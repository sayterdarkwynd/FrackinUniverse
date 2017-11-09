shoggothAcidAttack2 = {}

--------------------------------------------------------------------------------
function shoggothAcidAttack2.enter()
  if not hasTarget() then
    return nil
  end

  return {
    timer = config.getParameter("shoggothAcidAttack2.skillTime", 16),
    damagePerSecond = config.getParameter("shoggothAcidAttack2.damagePerSecond", 1600),
    distanceRange = config.getParameter("shoggothAcidAttack2.distanceRange"),
    winddownTimer = config.getParameter("shoggothAcidAttack2.winddownTime"),
    windupTimer = config.getParameter("shoggothAcidAttack2.windupTime"),
    periodTimer = config.getParameter("shoggothAcidAttack2.periodTime"),
    attacksLeft = config.getParameter("shoggothAcidAttack2.attacksLeft"),
    --initialPeriodTime = periodTimer,
    spitting = false
  }
end

--------------------------------------------------------------------------------
function shoggothAcidAttack2.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  monster.setActiveSkillName("shoggothAcidAttack2")
end

--------------------------------------------------------------------------------
function shoggothAcidAttack2.update(dt, stateData)
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
      if stateData.windupTimer == config.getParameter("shoggothAcidAttack2.windupTime") then
      animator.setAnimationState("movement", "idle5")
      
      self.randValNum = math.random(100)
      if self.randValNum >=50 then
        animator.playSound("attackMain")
      end      
	  animator.setParticleEmitterOffsetRegion("madUp", mcontroller.boundBox())
	  animator.setParticleEmitterActive("madUp", true)        
      end
      stateData.windupTimer = stateData.windupTimer - dt

    -- additional step here: iterate through three spits first
    elseif stateData.attacksLeft > 0 then
      if stateData.periodTimer < 0 then
        animator.playSound("madnessZone")
        shoggothAcidAttack2.spit(toTarget)
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

function shoggothAcidAttack2.spit(direction)
  local projectileType = config.getParameter("shoggothAcidAttack2.projectile.type")
  local projectileConfig = config.getParameter("shoggothAcidAttack2.projectile.config")
  local projectileOffset = config.getParameter("shoggothAcidAttack2.projectile.offset")
  local direction2 = vec2.add(direction, {0, 10})
  local direction3 = vec2.add(direction, {0, -10})

  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
  end


  world.spawnProjectile(projectileType, monster.toAbsolutePosition(projectileOffset), entity.id(), direction, true, projectileConfig)
end

function shoggothAcidAttack2.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  monster.setActiveSkillName("")
end

