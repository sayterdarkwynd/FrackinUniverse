--------------------------------------------------------------------------------
dollfaceLaserAttack = {}

function dollfaceLaserAttack.enter()
  if not hasTarget() then return nil end

  --rangedAttack.setConfig(config.getParameter("dollfaceLaserAttack.projectile.type"), config.getParameter("dollfaceLaserAttack.projectile.config"))

  return {
    timer = 0,
    timer2 = 0,
    firetimer = 0,
    fireInterval= config.getParameter("dollfaceLaserAttack.fireInterval"),
    bobTime = config.getParameter("dollfaceLaserAttack.bobTime"),
    bobHeight = config.getParameter("dollfaceLaserAttack.bobHeight"),
    skillTime = config.getParameter("dollfaceLaserAttack.skillTime"),
    direction = util.randomDirection(),
    basePosition = self.spawnPosition,
    cruiseDistance = config.getParameter("cruiseDistance")
  }
end

function dollfaceLaserAttack.enteringState(stateData)
  monster.setActiveSkillName("dollfaceLaserAttack")
  animator.setAnimationState("head", "laser", false)
end

function dollfaceLaserAttack.update(dt, stateData)
  mcontroller.controlFace(1)
  if not hasTarget() then return true end

  local projectileOffsets = config.getParameter("dollfaceLaserAttack.projectileOffsets")

  if stateData.timer2 <= 0 then
    for _,projectileOffset in pairs(projectileOffsets) do
      dollfaceLaserAttack.fire(projectileOffset)
      animator.playSound("laser")
    end
    stateData.timer2=stateData.fireInterval
  else stateData.timer2 = stateData.timer2 - dt end

  local position = mcontroller.position()

  local toTarget = world.distance(self.targetPosition, position)
  if toTarget[1] < -stateData.cruiseDistance or checkWalls(1) then
    stateData.direction = -1
  elseif toTarget[1] > stateData.cruiseDistance or checkWalls(-1) then
    stateData.direction = 1
  end

  stateData.timer = stateData.timer + dt
  local angle = 2.0 * math.pi * stateData.timer / stateData.bobTime
  local targetPosition = {
    position[1] + stateData.direction * 5,
    stateData.basePosition[2] + stateData.bobHeight * math.cos(angle)
  }
  flyTo(targetPosition)

  if stateData.timer > stateData.skillTime then
    mcontroller.controlFly({0,0})
    mcontroller.setVelocity({0,0})
    return true
  else
    return false
  end
end

function dollfaceLaserAttack.fire(offset)
  local projectileType = config.getParameter("dollfaceLaserAttack.projectile.type")
  local projectileConfig = config.getParameter("dollfaceLaserAttack.projectile.config")

  if projectileConfig.power then
    projectileConfig.power = projectileConfig.power * root.evalFunction("monsterLevelPowerMultiplier", monster.level())
  end

  local toTarget = vec2.norm(world.distance(self.targetPosition, monster.toAbsolutePosition(offset)))
  local projectile = world.spawnProjectile(projectileType, monster.toAbsolutePosition(offset), entity.id(), toTarget, false, projectileConfig)
end

function dollfaceLaserAttack.leavingState(stateData)
  animator.setAnimationState("head", "idle", false)
end
