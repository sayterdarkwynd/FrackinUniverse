--------------------------------------------------------------------------------
dollfaceSlamAttack = {}

function dollfaceSlamAttack.enter()
  if self.targetPosition == nil then return nil end

  shockwaveAttack.setConfig(
    config.getParameter("dollfaceSlamAttack.projectile.type"),
    config.getParameter("dollfaceSlamAttack.projectile.config"),
    config.getParameter("dollfaceSlamAttack.shockwaveBounds"),
    config.getParameter("dollfaceSlamAttack.shockwaveHeight"),
    config.getParameter("dollfaceSlamAttack.maxDistance"),
    config.getParameter("dollfaceSlamAttack.impactLine"),
    config.getParameter("dollfaceSlamAttack.directions")
  )

  return {
    slamHeight = config.getParameter("dollfaceSlamAttack.slamHeight"),
    riseSpeed = config.getParameter("dollfaceSlamAttack.riseSpeed"),
    slamSpeed = config.getParameter("dollfaceSlamAttack.slamSpeed"),
    timer = config.getParameter("dollfaceSlamAttack.skillTime"),
    stunDuration = config.getParameter("dollfaceSlamAttack.stunDuration"),
    prepareSlam = false,
    slam = false
  }
end

function dollfaceSlamAttack.enteringState(stateData)
  monster.setActiveSkillName("dollfaceSlamAttack")
end

function dollfaceSlamAttack.update(dt, stateData)
  mcontroller.controlFace(1)
  local position = mcontroller.position()

  stateData.timer = stateData.timer - dt
  if stateData.timer <= 0 then
    --Move back up
    local y = mcontroller.yPosition()
    local y2 = self.spawnPosition[2]
    if math.abs(y - y2) > 1 then
      flyTo({mcontroller.xPosition(), self.spawnPosition[2]})
      return false
    else
      mcontroller.controlFly({0,0})
      mcontroller.setYPosition(self.spawnPosition[2])
    end
    if animator.animationState("hands") == "idle" then return true
    else
      animator.setAnimationState("hands", "winddown", false)
      animator.resetTransformationGroup("lefthand")
      animator.resetTransformationGroup("righthand")
      return false
    end
  end

  --Move to above target
  if not stateData.prepareSlam then
    local approachPosition = {
      self.targetPosition[1],
      self.spawnPosition[2]
    }
    local toApproach = world.distance(approachPosition, position)

    if math.abs(toApproach[1]) < 3 or checkWalls(util.toDirection(toApproach[1])) then
      stateData.prepareSlam = true
    else
      flyTo(approachPosition)
      return false
    end
  end

  --Move up a bit before slamming
  if stateData.prepareSlam then
    local approachPosition = {
      position[1],
      self.spawnPosition[2] + stateData.slamHeight
    }

    if checkWalls(1) then
      approachPosition[1] = approachPosition[1] - 2
    end
    if checkWalls(-1) then
      approachPosition[1] = approachPosition[1] + 2
    end

    local toApproach = world.distance(approachPosition, position)

    if math.abs(toApproach[2]) < 1 then
      stateData.slam = true
    else
      flyTo(approachPosition, stateData.riseSpeed)
      if animator.animationState("hands")~="slam" then
        if animator.setAnimationState("hands", "windup", false) then
          animator.rotateTransformationGroup("lefthand", 45,{-5,-5})
          animator.rotateTransformationGroup("righthand", -45,{5,-5})
        end
      end
    end
  end

  --Slam and stay on ground for stun duration
  if stateData.slam then
    mcontroller.controlParameters({
      gravityEnabled = true
    })
    if mcontroller.onGround() then -- and not monster.isFiring() then
      if not stateData.landed then
        animator.playSound("slam")
        shockwaveAttack.fireShockwave()
      end
      stateData.landed = true
      if stateData.timer > stateData.stunDuration then
        stateData.timer = 0
      end
    else
      if not stateData.landed then
        monster.setDamageOnTouch(true)
      end
      mcontroller.controlApproachYVelocity(-config.getParameter("dollfaceSlamAttack.slamSpeed"), 100)
    end
  end

  return false
end

function dollfaceSlamAttack.leavingState(stateData)
  monster.setDamageOnTouch(false)
  mcontroller.controlFly({0,0})
  mcontroller.setVelocity({0,0})
end

function dollfaceSlamAttack.flyToTargetYOffsetRange(targetPosition)
  local position = mcontroller.position()
  local yOffsetRange = config.getParameter("targetYOffsetRange")
  local destination = {
    targetPosition[1],
    util.clamp(position[2], targetPosition[2] + yOffsetRange[1], targetPosition[2] + yOffsetRange[2])
  }

  if math.abs(destination[2] - position[2]) < 1.0 then
    return true
  else
    flyTo(destination)
  end

  return false
end

--do to the transformation we must never leave this state unless it actually finishes
function dollfaceSlamAttack.preventStateChange()
  return false
end
