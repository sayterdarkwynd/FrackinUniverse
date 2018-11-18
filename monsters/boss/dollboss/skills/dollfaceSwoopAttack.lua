dollfaceSwoopAttack = {}

function dollfaceSwoopAttack.enter()
  if not hasTarget() then return nil end
  if self.targetPosition == nil then return nil end

  local parameters = config.getParameter("dollfaceSwoopAttack.projectile.config")
  if parameters.power then
    parameters.power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * parameters.power
  end

  return {
    timer = 0.0,
    swoopTime = config.getParameter("dollfaceSwoopAttack.swoopTime"),
    tookDamage = false,
    projectile = config.getParameter("dollfaceSwoopAttack.projectile.type"),
    projectileConfig = parameters
  }
end

function dollfaceSwoopAttack.enteringState(stateData)
  monster.setActiveSkillName("dollfaceSwoopAttack")
end

function dollfaceSwoopAttack.update(dt, stateData)
  mcontroller.controlFace(1)
  if not hasTarget() then return true end

  local position = mcontroller.position()
  if stateData.basePosition == nil then
    stateData.basePosition = { self.targetPosition[1], position[2] }
    stateData.toTarget = world.distance(vec2.add(self.targetPosition, {0, 4.0}), position)

    monster.setDamageOnTouch(true)
  end

  stateData.timer = stateData.timer + dt

  local timerRatio = stateData.timer / stateData.swoopTime
  local angle = timerRatio * math.pi
  local targetPosition = {
    stateData.basePosition[1] - math.cos(angle) * stateData.toTarget[1],
    stateData.basePosition[2] + math.sin(angle) * stateData.toTarget[2]
  }
  local toTarget = world.distance(targetPosition, mcontroller.position())
  mcontroller.setVelocity(vec2.mul(toTarget, 1 / dt))

  local randAngle = math.random() * 2 * math.pi
  local magnitude = math.random() * 5
  local offset = vec2.rotate({magnitude,0},randAngle)
  world.spawnProjectile(stateData.projectile, vec2.add(mcontroller.position(),offset), entity.id(), {0,-1}, false, stateData.projectileConfig)

  if stateData.timer > stateData.swoopTime or checkWalls(util.toDirection(toTarget[1])) then
    return true
  else
    return false
  end
end


function dollfaceSwoopAttack.leavingState(stateData)
  monster.setDamageOnTouch(false)
  mcontroller.setVelocity({0,0})
end
