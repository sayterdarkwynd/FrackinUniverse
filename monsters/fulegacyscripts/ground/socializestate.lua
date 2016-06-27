socializeState = {
  searchRegion = { -10, -2, 10, 2 },

  cooldown = 20,

  minDistance = 2.5,
  maxDistance = 4,

  maxMoveTime = 4,
  emoteTime = 2,
  totalTime = 4,
}

function canSocialize()
  return not hasTarget() and not isCaptive()
end

function enterSocialize(partnerId)
  return self.state.pickState({ socializePartnerId = partnerId })
end

function socializeState.enter()
  if not canSocialize() then return nil end

  local partnerId = socializeState.findPartner()
  if partnerId == nil then return nil end

  if not world.callScriptedEntity(partnerId, "enterSocialize", entity.id()) then
    return nil
  end

  return {
    timer = 0,
    moveTimer = socializeState.maxMoveTime,
    emoteTimer = 0,
    partnerId = partnerId
  }
end

function socializeState.enterWith(params)
  if params.socializePartnerId == nil then return nil end
  if not canSocialize() then return nil end

  return {
    timer = 0,
    moveTimer = socializeState.maxMoveTime,
    emoteTimer = socializeState.emoteTime,
    partnerId = params.socializePartnerId
  }
end

function socializeState.update(dt, stateData)
  local partnerPosition = world.entityPosition(stateData.partnerId)
  if partnerPosition == nil then
    return true, socializeState.cooldown
  end

  local toPartner = world.distance(partnerPosition, self.position)
  local distance = math.abs(toPartner[1])
  if distance < socializeState.minDistance then
    move({ -toPartner[1], 0 }, false)
    stateData.moveTimer = stateData.moveTimer - dt
  elseif distance > socializeState.maxDistance then
    move({ toPartner[1], 0 }, false)
    stateData.moveTimer = stateData.moveTimer - dt
  else
    mcontroller.controlFace(toPartner[1])

    if stateData.emoteTimer ~= nil then
      stateData.emoteTimer = stateData.emoteTimer - dt
      if stateData.emoteTimer <= 0 then
        stateData.emoteTimer = nil
        controlJump()
      end
    end

    move({ 0, 0 }, false)

    stateData.timer = stateData.timer + dt
    if stateData.timer > socializeState.totalTime then
      return true, socializeState.cooldown
    end
  end

  if stateData.moveTimer <= 0 then
    return true, socializeState.cooldown
  end

  return false
end

function socializeState.findPartner()
  local min = vec2.add({ socializeState.searchRegion[1], socializeState.searchRegion[2] }, self.position)
  local max = vec2.add({ socializeState.searchRegion[3], socializeState.searchRegion[4] }, self.position)
  local entityIds = world.entityQuery(min, max, { includedTypes = {"monster"}, withoutEntityId = entity.id(), callScript = "canSocialize" })
  if #entityIds > 0 then
    return entityIds[1]
  end

  return nil
end
