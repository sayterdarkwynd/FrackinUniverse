herdFleeState = {
  duration = 10,
  notificationRadius = 5,
  notificationInterval = 1
}

function herdFleeState.enterWith(params)
  if self.aggressive then return nil end

  local direction = nil

  if params.familyMemberDamagedBy ~= nil then
    local damageSourcePosition = world.entityPosition(params.familyMemberDamagedBy)
    if damageSourcePosition == nil then return nil end

    local fromSource = world.distance(self.position, damageSourcePosition)
    direction = util.toDirection(fromSource[1])
  end

  if params.familyMemberFleeDirection ~= nil then
    direction = params.familyMemberFleeDirection
  end

  if direction == nil then return nil end
  return {
    direction = direction,
    timer = 0,
    notificationTimer = herdFleeState.notificationInterval
  }
end

function herdFleeState.enteringState(stateData)
end

function herdFleeState.update(dt, stateData)
  move({ stateData.direction, 0 }, true)

  stateData.notificationTimer = stateData.notificationTimer - dt
  if stateData.notificationTimer <= 0 then
    local entityId = entity.id()
    local familyMemberEntityIds = world.entityQuery(self.position, herdFleeState.notificationRadius, {
      includedTypes = {"monster"},
      withoutEntityId = entityId,
      callScript = "entity.seed",
      callScriptResult = entity.seed()
    })

    for _, familyMemberEntityId in pairs(familyMemberEntityIds) do
      world.callScriptedEntity(familyMemberEntityId, "self.state.pickState", { familyMemberFleeDirection = stateData.direction })
    end

    stateData.notificationTimer = herdFleeState.notificationInterval
  end

  stateData.timer = stateData.timer + dt
  return stateData.timer > herdFleeState.duration
end

function herdFleeState.leavingState(stateData)
end
