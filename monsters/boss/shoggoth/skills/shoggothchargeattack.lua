shoggothChargeAttack = {}

--------------------------------------------------------------------------------
function shoggothChargeAttack.enter()
  if not hasTarget() then
    return nil
  end
  monster.setDamageOnTouch(true)


  return {
    timer = config.getParameter("shoggothChargeAttack.skillTime", 0.14),
    damagePerSecond = config.getParameter("shoggothChargeAttack.damagePerSecond", 5000),
    distanceRange = config.getParameter("shoggothChargeAttack.distanceRange"),
    intervalTime = config.getParameter("shoggothChargeAttack.intervalTime"),
    currentPeriod = config.getParameter("shoggothChargeAttack.intervalTime"),
    swiping = false
  }
end

--------------------------------------------------------------------------------
function shoggothChargeAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")

  monster.setActiveSkillName("shoggothChargeAttack")
end

--------------------------------------------------------------------------------
function shoggothChargeAttack.update(dt, stateData)
  if not hasTarget() then return true end
  local toTarget = world.distance(self.targetPosition, mcontroller.position())
  local targetDir = util.toDirection(toTarget[1])

  if not stateData.swiping then 
    
    --projectile interval check and spawn
    if stateData.currentPeriod < 0 then
      if isBlocked() then
      local crashTiles = {}
      local basePos = config.getParameter("projectileSourcePosition", {0, 0})
      for xOffset = 2, 22 do
        for yOffset = -14.5, 10 do
          table.insert(crashTiles, monster.toAbsolutePosition({basePos[1] + xOffset, basePos[2] + yOffset}))
        end
      end
      
      self.randValNum = math.random(100)
      if self.randValNum >=99 then
        animator.playSound("attackMain")
      end      
      animator.playSound("shoggothChomp")
      world.damageTiles(crashTiles, "foreground", monster.toAbsolutePosition({10, 0}), "plantish", 30)
    end
      -- shoggothChargeAttack.chomp(targetDir)
      stateData.currentPeriod = stateData.intervalTime
    else
      stateData.currentPeriod = stateData.currentPeriod - dt
    end

    if math.abs(toTarget[1]) > stateData.distanceRange[2] then
      animator.setAnimationState("movement", "run")
      move(toTarget, true)
    elseif math.abs(toTarget[1]) < stateData.distanceRange[1] then
      move({-toTarget[1], toTarget[2]}, true)
      animator.setAnimationState("movement", "run")
      mcontroller.controlFace(targetDir)
    else
      stateData.swiping = true
    end
  end

  return false
end


function shoggothChargeAttack.chomp(direction)
  local projectileType = config.getParameter("shoggothChargeAttack.projectile.type")
  local projectileConfig = config.getParameter("shoggothChargeAttack.projectile.config")
  local projectileOffset = config.getParameter("shoggothChargeAttack.projectile.offset")
  world.spawnProjectile(projectileType, monster.toAbsolutePosition(projectileOffset), entity.id(), {direction, 0}, true, projectileConfig)
end

function shoggothChargeAttack.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  monster.setActiveSkillName("")
end