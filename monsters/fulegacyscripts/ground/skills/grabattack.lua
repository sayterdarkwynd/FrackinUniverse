grabAttack = {
  maxHoldDistance = { 3, 4 },
  estimatedTargetMass = 0.6,
  maxMoveTime = 5,
  maxDistanceMismatch = 1,
  holdTime = 3
}

function grabAttack.enter()
  if not canStartSkill("grabAttack") then return nil end

  return { run = coroutine.wrap(grabAttack.run) }
end

function grabAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  animator.setAnimationState("attack", "idle")

  monster.setActiveSkillName("grabAttack")
end

function grabAttack.update(dt, stateData)
  if not hasTarget() then return true end

  return stateData.run(stateData)
end

function grabAttack.leavingState(stateData)
end

function grabAttack.run(stateData)
  mcontroller.controlFace(self.toTarget[1])

  if math.abs(self.toTarget[1]) - grabAttack.maxHoldDistance[1] > grabAttack.maxDistanceMismatch then
    return true
  end

  local timer = grabAttack.maxMoveTime
  util.wait(grabAttack.holdTime, function()
    if not grabAttack.withinHoldDistance() then
      animator.setAnimationState("attack", "idle")
      if timer > 0 then
        move({ self.toTarget[1], 0 }, true)
        timer = timer - script.updateDt()
        return false
      else
        return true
      end
    end
    animator.setAnimationState("movement", "idle")
    animator.setAnimationState("attack", "shooting")
    world.spawnProjectile("grabbed", world.entityPosition(self.target), entity.id(), { 0, 0 }, false)
  end)

  return true
end

function grabAttack.withinHoldDistance()
  return math.abs(self.toTarget[1]) <= grabAttack.maxHoldDistance[1] and
    math.abs(self.toTarget[2]) <= grabAttack.maxHoldDistance[2]
end
