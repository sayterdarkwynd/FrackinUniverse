eyeBeamAttack = {}

--------------------------------------------------------------------------------
function eyeBeamAttack.enter()
  if not hasTarget() then
    return {
    timer = config.getParameter("eyeBeamAttack.skillTime", 2),
    damagePerSecond = config.getParameter("eyeBeamAttack.damagePerSecond", 0),
    distanceRange = config.getParameter("eyeBeamAttack.distanceRange"),
    winddownTimer = config.getParameter("eyeBeamAttack.winddownTime"),
    windupTimer = config.getParameter("eyeBeamAttack.windupTime"),
    targetSnapshot = {0, 0},
    blasting = false    
    }
  end

  return {
    timer = config.getParameter("eyeBeamAttack.skillTime", 2),
    damagePerSecond = config.getParameter("eyeBeamAttack.damagePerSecond", 0),
    distanceRange = config.getParameter("eyeBeamAttack.distanceRange"),
    winddownTimer = config.getParameter("eyeBeamAttack.winddownTime"),
    windupTimer = config.getParameter("eyeBeamAttack.windupTime"),
    targetSnapshot = {0, 0},
    blasting = false
  }
end

--------------------------------------------------------------------------------
function eyeBeamAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  monster.setActiveSkillName("eyeBeamAttack")
end

--------------------------------------------------------------------------------
function eyeBeamAttack.update(dt, stateData)
  if not hasTarget() then return true end
  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])
  if (targetDir == 1) then 
    toTargetAim = world.distance(self.targetPosition, vec2.add(mcontroller.position(), {10, -5}))
  else
    toTargetAim = world.distance(self.targetPosition, vec2.add(mcontroller.position(), {-10, -5}))
  end

  if not stateData.blasting then 
    if math.abs(toTarget[1]) > stateData.distanceRange[2] then
      animator.setAnimationState("movement", "walk")
      move(toTarget, false)
    elseif math.abs(toTarget[1]) < stateData.distanceRange[1] then
      move({-toTarget[1], toTarget[2]}, false)
      animator.setAnimationState("movement", "walk")
      mcontroller.controlFace(targetDir)
    else
      stateData.blasting = true
    end
  else
    mcontroller.controlFace(targetDir)

    -- This part controls the phases of the attack. At the end of each timer expiration
    --   the next animation is started. Then the control falls through to the next phase.

    if stateData.windupTimer > 0 then
      if stateData.windupTimer == config.getParameter("eyeBeamAttack.windupTime") then
      animator.setAnimationState("movement", "idle")
      animator.setAnimationState("firstBeams", "active")
      animator.playSound("turnHostile")
      end
      stateData.windupTimer = stateData.windupTimer - dt
      if stateData.windupTimer  < 0 then
          animator.setLightActive("beam1", true)
          animator.setAnimationState("firstBeams", "active")
          
          -- rotate the eyebeam animation to aim at user
          local animationAngle = math.atan(-toTargetAim[2], math.abs(toTargetAim[1]))
          animator.rotateGroup("projectileAim", animationAngle)
          entity.targetSnapshot = toTargetAim

      end
      return false

    elseif stateData.timer > 0 then

      eyeBeamAttack.blast(entity.targetSnapshot)
      stateData.timer = stateData.timer - dt
      if stateData.timer < 0 then
        animator.setAnimationState("firstBeams", "winddown")
        animator.setLightActive("beam1", false)

      end
      return false

    -- phase 3 - winddown (profit)
    elseif stateData.winddownTimer > 0 then
      stateData.winddownTimer = stateData.winddownTimer - dt
    else
      stateData.blasting = false
      return true
    end
  end


  return false
end

function eyeBeamAttack.blast(direction)
  local projectileType = config.getParameter("eyeBeamAttack.projectile.type")
  local projectileConfig = config.getParameter("eyeBeamAttack.projectile.config")
  local projectileOffset = config.getParameter("eyeBeamAttack.projectile.offset")


  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
  end

  world.spawnProjectile(projectileType, monster.toAbsolutePosition(projectileOffset), entity.id(), direction, true, projectileConfig)
end

function eyeBeamAttack.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  animator.setAnimationState("firstBeams", "idle")
  monster.setActiveSkillName("")
end

