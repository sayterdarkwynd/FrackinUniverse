blinkAttack = {
  initialDelay = 1,
  postBlinkDelay = 0.2,
  chargeDuration = 0.25,
}

function blinkAttack.enter()
  if not canStartSkill("blinkAttack") then return nil end

  local destination = blinkAttack.findDestination(world.entityPosition(self.target))
  if destination == nil then return nil end

  return {
    originalDestination = destination,
    run = coroutine.wrap(blinkAttack.run)
  }
end

function blinkAttack.enteringState(stateData)
  entity.setAnimationState("movement", "idle")
  entity.setAnimationState("attack", "idle")

  entity.setActiveSkillName("blinkAttack")
end

function blinkAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  return stateData.run(stateData)
end

function blinkAttack.leavingState(stateData)
end

function blinkAttack.run(stateData)
  blinkAttack.wait(blinkAttack.initialDelay, function()
    if self.toTarget ~= nil then
      mcontroller.controlFace(self.toTarget[1])
    end
  end)

  -- Might have a better destination at this point
  local destination = blinkAttack.findDestination(world.entityPosition(self.target))
  if destination == nil then
    destination = stateData.originalDestination
  end

  if self.toTarget ~= nil then
    mcontroller.controlFace(self.toTarget[1])
  end

  entity.burstParticleEmitter("blinkout")
  mcontroller.setVelocity({ 0, 0 })
  mcontroller.setPosition(destination)
  coroutine.yield(false)

  blinkAttack.wait(blinkAttack.postBlinkDelay, function()
    if self.toTarget ~= nil then
      mcontroller.controlFace(self.toTarget[1])
    end
  end)

  return true
end

function blinkAttack.wait(duration, action)
  local timer = 0
  while timer < duration do
    if action ~= nil then action() end

    timer = timer + script.updateDt()
    coroutine.yield(false)
  end
end

function blinkAttack.findDestination(targetPosition)
  if targetPosition == nil then return nil end

  local collisionPoly = mcontroller.collisionPoly()
  local direction = util.toDirection(self.toTarget[1])
  local offsetXRange = entity.configParameter("blinkAttack.offsetXRange")

  for offsetX = offsetXRange[2], offsetXRange[1], -1 do
    local destinationPosition = {targetPosition[1] + direction * offsetX, targetPosition[2]}
    local resolvedPosition = world.resolvePolyCollision(collisionPoly, destinationPosition, 0.5)
    if resolvedPosition then
      return resolvedPosition
    end
  end

  return nil
end
