--------------------------------------------------------------------------------
dieState = {}

function dieState.enterWith(params)
  if not params.die then return nil end

  --rangedAttack.setConfig(config.getParameter("projectiles.deathexplosion.type"), , 0.2)
  local parameters = config.getParameter("projectiles.deathexplosion.config")
  if parameters.power then
    parameters.power = root.evalFunction("monsterLevelPowerMultiplier", monster.level()) * parameters.power
  end

  return {
    timer = 3,
    rotateInterval = 0.1,
    rotateAngle = 0.05,
    deathSound = true,
    projectile = config.getParameter("projectiles.deathexplosion.type"),
    projectileConfig = parameters
  }
end

function dieState.update(dt, stateData)
  stateData.timer = stateData.timer - dt

  local angle = dieState.angleFactorFromTime(stateData.timer, stateData.rotateInterval) * stateData.rotateAngle - stateData.rotateAngle / 2
  animator.rotateGroup("all", angle, true)

  stateData.timer = stateData.timer - dt

  if stateData.timer < 0.2 and stateData.deathSound then
    animator.playSound("death")
    world.spawnProjectile(stateData.projectile, mcontroller.position(), entity.id(), {1,0}, false, stateData.projectileConfig)
    stateData.deathSound = false
  end

  if stateData.timer < 0 then
    self.dead = true
  end


  return false
end

--basic triangle wave
function dieState.angleFactorFromTime(timer, interval)
  local modTime = interval - (timer % interval)
  if modTime < interval / 2 then
    return modTime / (interval / 2)
  else
    return (interval - modTime) / (interval / 2)
  end
end
