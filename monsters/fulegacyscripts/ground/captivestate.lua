captiveState = {
  closeDistance = 4,
  runDistance = 12,
  teleportDistance = 36,
}

function captiveState.enter()
  if not isCaptive() or hasTarget() then return nil end

  return { running = false }
end

function captiveState.enterWith(params)
  if not isCaptive() then return nil end

  -- We're masquerading as wander for captive monsters
  if params.wander then
    return { running = false }
  end

  return nil
end

function captiveState.update(dt, stateData)
  if hasTarget() then return true end

  -- Translate owner uuid to entity id
  capturepod.updateOwnerEntityId()

  -- Owner is nowhere around
  if self.ownerEntityId == nil then
    return false
  end

  local ownerPosition = world.entityPosition(self.ownerEntityId)
  local toOwner = world.distance(ownerPosition, self.position)
  local distance = math.abs(toOwner[1])

  local movement
  if distance > captiveState.teleportDistance then
    movement = 0
    mcontroller.setPosition(ownerPosition)
  elseif distance < captiveState.closeDistance then
    stateData.running = false
    movement = 0
  elseif toOwner[1] < 0 then
    movement = -1
  elseif toOwner[1] > 0 then
    movement = 1
  end

  if distance > captiveState.runDistance then
    stateData.running = true
  end

  animator.setAnimationState("attack", "idle")
  move({ movement, toOwner[2] }, stateData.running, captiveState.closeDistance)

  return false
end
