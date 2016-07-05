shoggothChargeAttack = {}

--------------------------------------------------------------------------------
function shoggothChargeAttack.enter()
  if not hasTarget() then
    return nil
  end
  entity.setDamageOnTouch(true)


  return {
    timer = entity.configParameter("shoggothChargeAttack.skillTime", 0.24),
    damagePerSecond = entity.configParameter("shoggothChargeAttack.damagePerSecond", 5000),
    distanceRange = entity.configParameter("shoggothChargeAttack.distanceRange"),
    intervalTime = entity.configParameter("shoggothChargeAttack.intervalTime"),
    currentPeriod = entity.configParameter("shoggothChargeAttack.intervalTime"),
    swiping = false
  }
end

--------------------------------------------------------------------------------
function shoggothChargeAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")

  entity.setActiveSkillName("shoggothChargeAttack")
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
      --CRASH
      -- entity.playSound("chargeCrash")

      local crashTiles = {}
      local basePos = entity.configParameter("projectileSourcePosition", {0, 0})
      for xOffset = 2, 22 do
        for yOffset = -14.5, 10 do
          table.insert(crashTiles, object.toAbsolutePosition({basePos[1] + xOffset, basePos[2] + yOffset}))
        end
      end
      entity.playSound("shoggothChomp")
      world.damageTiles(crashTiles, "foreground", object.toAbsolutePosition({10, 0}), "plantish", 20)

      -- self.state.pickState({stun=true,duration=entity.configParameter("chargeAttack.crashStunTime")})
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
  local projectileType = entity.configParameter("shoggothChargeAttack.projectile.type")
  local projectileConfig = entity.configParameter("shoggothChargeAttack.projectile.config")
  local projectileOffset = entity.configParameter("shoggothChargeAttack.projectile.offset")
  world.spawnProjectile(projectileType, object.toAbsolutePosition(projectileOffset), entity.id(), {direction, 0}, true, projectileConfig)
end

function shoggothChargeAttack.leavingState(stateData)
  animator.setAnimationState("movement", "idle")
  entity.setActiveSkillName("")
end