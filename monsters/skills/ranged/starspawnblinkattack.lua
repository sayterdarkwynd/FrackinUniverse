starspawnBlinkAttack = {
  initialDelay = 1,
  postBlinkDelay = 0.2,
  chargeDuration = 0.25,
}

function starspawnBlinkAttack.enter()
  if not canStartSkill("starspawnBlinkAttack") then return nil end

  local destination = starspawnBlinkAttack.findDestination(world.entityPosition(self.target))
  if destination == nil then return nil end

  return {
    originalDestination = destination,
    run = coroutine.wrap(starspawnBlinkAttack.run)
  }
end

function starspawnBlinkAttack.enteringState(stateData)
  animator.setAnimationState("movement", "idle")
  animator.setAnimationState("attack", "idle")

  monster.setActiveSkillName("starspawnBlinkAttack")
end

function starspawnBlinkAttack.update(dt, stateData)
  if not canContinueSkill() then return true end

  return stateData.run(stateData)
end

function starspawnBlinkAttack.leavingState(stateData)
end

function starspawnBlinkAttack.run(stateData)
  starspawnBlinkAttack.wait(starspawnBlinkAttack.initialDelay, function()
    if self.toTarget ~= nil then
      mcontroller.controlFace(self.toTarget[1])
    end
  end)

  -- Might have a better destination at this point
  local destination = starspawnBlinkAttack.findDestination(world.entityPosition(self.target))
  if destination == nil then
    destination = stateData.originalDestination
  end

  if self.toTarget ~= nil then
    mcontroller.controlFace(self.toTarget[1])
  end

  animator.burstParticleEmitter("blinkout")
  animator.playSound("blinkSound")
  mcontroller.setVelocity({ 0, 0 })
  mcontroller.setPosition(destination)
  coroutine.yield(false)

  starspawnBlinkAttack.wait(starspawnBlinkAttack.postBlinkDelay, function()
    if self.toTarget ~= nil then
      mcontroller.controlFace(self.toTarget[1])
    end
  end)

  return true
end

function starspawnBlinkAttack.wait(duration, action)
  local timer = 0
  while timer < duration do
    if action ~= nil then action() end

    timer = timer + script.updateDt()
    coroutine.yield(false)
  end
end

function starspawnBlinkAttack.findDestination(targetPosition)
  if targetPosition == nil then return nil end

  local collisionPoly = mcontroller.collisionPoly()
  local direction = util.toDirection(self.toTarget[1])
  local offsetXRange = config.getParameter("starspawnBlinkAttack.offsetXRange")

  for offsetX = offsetXRange[2], offsetXRange[1], -1 do
    local destinationPosition = {targetPosition[1] + direction * offsetX, targetPosition[2]}
    local resolvedPosition = world.resolvePolyCollision(collisionPoly, destinationPosition, 0.5)
    if resolvedPosition then
      return resolvedPosition
    end
  end

  return nil
end
