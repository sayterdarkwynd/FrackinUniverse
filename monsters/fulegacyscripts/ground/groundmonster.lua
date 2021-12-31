require "/scripts/util.lua"

function init()
  self.position = {0, 0}

  -- 0 for inside territory, -1 for territory to the left of us, 1 for
  -- territory to the right of us.
  self.territory = 0

  self.target = 0
  self.toTarget = {0, 0}
  self.fromTarget = {0, 0}

  self.lastTargetPosition = {0, 0}
  self.staleTargetTime = 1.0
  self.staleTargetTimer = 0
  self.skillOptions = {}
  self.noOptionCount = 0

  self.aggressive = config.getParameter("aggressive", false)
  setAggressive(false, false)

  if capturepod ~= nil then
    capturepod.onInit()
  end

  self.skillTimer = 0

  self.targetSearchTimer = 0
  self.targetHoldTimer = 0

  self.lastAggressGroundPosition = {0, 0}
  self.stuckCount = 0
  self.stuckPosition = {0, 0}
  self.onGround = mcontroller.onGround()

  self.pathing = {}
  self.pathing.stuckTimer = 0
  self.pathing.maxStuckTime = 2

  self.movementParameters = mcontroller.baseParameters()
  self.jumpHoldTime = self.movementParameters.airJumpProfile.jumpHoldTime
  self.jumpSpeed = self.movementParameters.airJumpProfile.jumpSpeed
  self.runSpeed = self.movementParameters.runSpeed

  self.facingTimer = 0
  self.facingCooldown = 0.5

  self.scriptDelta = 10

  self.jumpTimer = 0
  self.jumpCooldown = 0
  self.jumpMaxCooldown = 1

  local states = stateMachine.scanScripts(config.getParameter("scripts"), "(%a+State)%.lua")
  local attacks = stateMachine.scanScripts(config.getParameter("scripts"), "(%a+Attack)%.lua")
  for _, attack in pairs(attacks) do
    table.insert(states, 1, attack)
  end
  local specials = stateMachine.scanScripts(config.getParameter("scripts"), "(%a+Special)%.lua")
  for _, special in pairs(specials) do
    table.insert(states, 1, special)
  end

  self.globalCooldown = config.getParameter("globalCooldown", 0.75)
  self.skillCooldownTimers = {}
  self.skillParameters = {}
  for _, skillName in pairs(config.getParameter("skills")) do
    local params = config.getParameter(skillName)

    --create generic attacks from factories
    if params and params.factory then
      if type(_ENV[params.factory]) == "function" then
        if not _ENV[skillName] then
          _ENV[skillName] = _ENV[params.factory](skillName)
          table.insert(states, 1, skillName)
        else
          sb.logInfo("Failed to create skill %s from factory %s: Table %s already exists in this context", skillName, params.factory, skillName)
        end
      else
        sb.logInfo("Failed to create skill %s from factory %s: factory function does not exist in this context", skillName, params.factory)
      end
    end

    self.skillParameters[skillName] = loadSkillParameters(skillName)
    self.skillCooldownTimers[skillName] = 0

    --run skill onInit hooks
    if type(_ENV[skillName].onInit) == "function" then
      _ENV[skillName].onInit()
    end
  end

  self.skillChains = {}

  self.state = stateMachine.create(states)

  self.state.enteringState = function(stateName)
    if isSkillState(stateName) then
      self.skillTimer = self.skillParameters[stateName].skillTimeLimit

      --increment or reset the attack chain tracker
      if self.skillChains[stateName] then
        self.skillChains[stateName] = self.skillChains[stateName] + 1
      else
        self.skillChains = { [stateName] = 1 }
      end
    end
  end

  self.state.leavingState = function(stateName)
    monster.setActiveSkillName(nil)
    if isSkillState(stateName) then
      setAggressive(true, false)
      for k in pairs(self.skillCooldownTimers) do
        if k == stateName then
          self.skillCooldownTimers[k] = self.skillParameters[k].cooldownTime
        else
          self.skillCooldownTimers[k] = math.max(self.skillCooldownTimers[k], self.globalCooldown)
        end
      end
    end
  end

  monster.setDeathSound("deathPuff")
  monster.setDeathParticleBurst(config.getParameter("deathParticles"))

  -- sb.logInfo("Unique Parameters: %s", entity.uniqueParameters())
  animator.setGlobalTag("backwards", "")

  self.debug = false
end

-------------------------------------------------------------------------------
-- react to a notification from another entity
function receiveNotification(notification)
  return self.state.pickState({ notification = notification })
end

--------------------------------------------------------------------------------
-- get the skill parameters from the relevant config parameter and make necessary adjustments
function loadSkillParameters(skillName)
  -- sb.logInfo("%s %s loading parameters for skill %s", entity.type(), entity.id(), skillName)
  if type(_ENV[skillName].loadSkillParameters) == "function" then
    return _ENV[skillName].loadSkillParameters()
  elseif config.getParameter(skillName) then
    local params = config.getParameter(skillName)

    local xAdjust = config.getParameter("projectileSourcePosition", {0, 0})[1]
    local yAdjust = -(mcontroller.boundBox()[2] + 2.5) + config.getParameter("projectileSourcePosition", {0, 0})[2]

    for i, rect in ipairs(params.startRects) do
      local startRect = normalizeRect(rect)

      --adjust rect for monster mouth position
      if startRect[1] > 0 then
        startRect[1] = startRect[1] + xAdjust
      elseif startRect[1] < 0 then
        startRect[1] = startRect[1] - xAdjust
      end
      if startRect[3] > 0 then
        startRect[3] = startRect[3] + xAdjust
      elseif startRect[1] < 0 then
        startRect[3] = startRect[3] - xAdjust
      end

      --adjust rect for monster standing height compared to player
      startRect[2] = startRect[2] + yAdjust
      startRect[4] = startRect[4] + yAdjust

      params.startRects[i] = startRect

      --adjust corresponding approachPoint
      local approachPoint = params.approachPoints[i]
      if approachPoint[1] > 0 then
        approachPoint[1] = approachPoint[1] + xAdjust
      elseif approachPoint[1] < 0 then
        approachPoint[1] = approachPoint[1] - xAdjust
      end

      approachPoint[2] = approachPoint[2] + yAdjust

      params.approachPoints[i] = approachPoint
    end

    return params
  else
    sb.logInfo("Unable to load parameters for skill %s!", skillName)
  end
end

--------------------------------------------------------------------------------
function damage(args)
  if capturepod ~= nil and capturepod.onDamage(args) then
    return
  end

  --execute skill onDamage hooks
  for skillName in pairs(self.skillParameters) do
    if type(_ENV[skillName].onDamage) == "function" then
      _ENV[skillName].onDamage(args)
    end
  end

  if args.damage > 0 then
    local entityId = entity.id()
    local damageNotificationRegion = config.getParameter("damageNotificationRegion", { -10, -4, 10, 4 })
    world.entityQuery(
      vec2.add({ damageNotificationRegion[1], damageNotificationRegion[2] }, self.position),
      vec2.add({ damageNotificationRegion[3], damageNotificationRegion[4] }, self.position),
      {
        includedTypes = {"monster"},
        withoutEntityId = entityId,
        callScript = "monsterDamaged",
        callScriptArgs = { entityId, monster.seed(), args.sourceId }
      }
    )

    if status.resource("health") <= 0 then
      if world.entityType(args.sourceId) == "monster" or world.entityType(args.sourceId) == "npc" then
        world.callScriptedEntity(args.sourceId, "monsterKilled", entity.id())
      end
    else
      if args.sourceId ~= self.target and args.sourceId ~= 0 and entity.isValidTarget(args.sourceId) then
        setTarget(args.sourceId)
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Called when a nearby monster has been damaged (by anything)
function monsterDamaged(entityId, entitySeed, damageSourceId)
  if entitySeed == monster.seed() then
    self.state.pickState({ familyMemberDamagedBy = damageSourceId })
  end
end

--------------------------------------------------------------------------------
-- Called when a monster has been killed, on the entity that dealt the death-blow
function monsterKilled(entityId)
  if capturepod ~= nil then
    capturepod.onMonsterKilled()
  end
end

--------------------------------------------------------------------------------
function die()
  if capturepod ~= nil then
    capturepod.onDie()
  end
end

--------------------------------------------------------------------------------
function update(dt)
  self.position = mcontroller.position()
  self.onGround = mcontroller.onGround()

  if storage.basePosition == nil then
    storage.basePosition = self.position
  end

  local inState = self.state.stateDesc()

  util.debugText(inState, mcontroller.position(), "blue")

  --don't automatically switch states in combat
  self.state.autoPickState = not hasTarget()

  --execute skill onUpdate hooks
  for skillName in pairs(self.skillParameters) do
    if type(_ENV[skillName].onUpdate) == "function" then
      _ENV[skillName].onUpdate(dt)
    end
  end

  local stuns = status.statusProperty("stuns", {})
  local slows = status.statusProperty("slows", {})

  local stunned = false
  if next(stuns) then
    stunned = true
    animator.setAnimationRate(0)
  end
  if not stunned then
    local animSpeed = 1.0
    for _, v in pairs(slows) do
      animSpeed = animSpeed * v
    end
    animator.setAnimationRate(animSpeed)
  end

  if stunned then
    --do nothin
  elseif inState == "stunState" or inState == "fleeState" then
    self.state.update(dt)
  else
    checkTerritory()
    track()

    if not inSkill() and hasTarget() then
      --calculate skill positions relative to target
      updateSkillOptions()

      --this should end up in skills, approach, or fall back into flee
      if inState ~= "approachState" then self.state.pickState() end
    end

    if not self.state.update(dt) then
      if hasTarget() then
        -- Force flee
        self.state.pickState({flee = true})
      else
        -- Force wandering
        self.state.pickState({wander = true})
      end
    end
  end

  if hasTarget() and self.debug then
    debugSkillOptions()
  end

  script.setUpdateDelta(hasTarget() and 1 or self.scriptDelta)

  if hasTarget() then script.setUpdateDelta(1) end

  if not self.moved and not hasTarget() then script.setUpdateDelta(self.scriptDelta) end

  if mcontroller.facingDirection() == mcontroller.movingDirection() then
    animator.setGlobalTag("backwards", "")
  else
    animator.setGlobalTag("backwards", "backwards")
  end

  decrementTimers()
end

--------------------------------------------------------------------------------
function move(delta, run, jumpThresholdX)
  mcontroller.controlMove(delta[1], run)
  self.pathing.deltaX = util.toDirection(delta[1])

  if self.jumpTimer <= 0 then
    if jumpThresholdX == nil then jumpThresholdX = 4 end

    -- We either need to be blocked by something, the target is above us and
    -- we are about to fall, or the target is significantly high above us
    local doJump = false
    if isBlocked() then
      doJump = true
    elseif (delta[2] >= 0 and willFall() and math.abs(delta[1]) > 7) then
      doJump = true
    elseif (math.abs(delta[1]) < jumpThresholdX and delta[2] > config.getParameter("jumpTargetDistance")) then
      doJump = true
    end

    if doJump then
      controlJump()
    end
  end

  if delta[2] < 0 then
    mcontroller.controlDown()
  end

  if delta[1] ~= 0 then
    setMovementState(run)
    return true
  else
    setIdleState()
    return false
  end

  if not self.onGround then
    animator.setAnimationState("movement", "jump")
  elseif delta[1] ~= 0 then
    animator.setAnimationState("movement", "run")
  else
    animator.setAnimationState("movement", "idle")
    return false
  end
end

function controlJump()
  if mcontroller.onGround() then
    mcontroller.controlJump()
  end
end

--------------------------------------------------------------------------------
-- NOTE: this will be inaccurate if called more than once per tick
function checkStuck()
  local newPos = mcontroller.position()
  if newPos[1] == self.stuckPosition[1] and newPos[2] == self.stuckPosition[2] then
    self.stuckCount = self.stuckCount + 1
  else
    self.stuckCount = 0
    self.stuckPosition = newPos
  end

  return self.stuckCount
end

--------------------------------------------------------------------------------
function calculateSeparationMovement()
  local entityIds = world.entityQuery(self.position, 0.5, { includedTypes = {"monster"}, withoutEntityId = entity.id(), order = "nearest" })
  if #entityIds > 0 then
    local separationMovement = world.distance(self.position, world.entityPosition(entityIds[1]))
    return util.toDirection(separationMovement[1])
  end

  return 0
end

--------------------------------------------------------------------------------
function travelTime(distance)
  local runSpeed = mcontroller.baseParameters().runSpeed
  return math.abs(distance / runSpeed)
end

--------------------------------------------------------------------------------
-- estimate the maximum jump duration
function jumpTime()
  return (2 * mcontroller.baseParameters().airJumpProfile.jumpSpeed) / (world.gravity(mcontroller.position()) * 1.5)
end

--------------------------------------------------------------------------------
-- estimate the maximum jump height
function jumpHeight()
  return (mcontroller.baseParameters().airJumpProfile.jumpSpeed * jumpTime()) / 4
end

--------------------------------------------------------------------------------
function faceTarget()
  if self.onGround then
    mcontroller.controlFace(self.toTarget[1])
  end
end

--------------------------------------------------------------------------------
function controlFace(direction)
  if self.onGround then
    mcontroller.controlFace(direction)
  end
end

--------------------------------------------------------------------------------
function isBlocked(direction)
  local direction = direction or mcontroller.facingDirection()
  local position = mcontroller.position()
  position[1] = position[1] + direction

  if not world.resolvePolyCollision(mcontroller.collisionPoly(), position, 0.8) then
    return true
  end
  return false
end

--------------------------------------------------------------------------------
function willFall(direction)
  local direction = direction or mcontroller.facingDirection()
  local position = mcontroller.position()
  position[1] = position[1] + direction
  --Snap the position forward
  position[1] = direction > 0 and math.ceil(position[1]) or math.floor(position[1])

  local bounds = mcontroller.boundBox()

  local groundRegion = {
    math.floor(position[1] + bounds[1]), math.ceil(position[2] + bounds[2] - 1),
    math.ceil(position[1] + bounds[3]), math.ceil(position[2] + bounds[2])
  }
  if world.rectTileCollision(groundRegion, {"Null", "Block", "Dynamic", "Platform"}) then
    return false
  end
  return true
end

--------------------------------------------------------------------------------
function checkTerritory()
  local tdist = config.getParameter("territoryDistance")
  local hdist = world.distance(self.position, storage.basePosition)[1]

  if hdist > tdist then
    self.territory = -1
    return
  elseif hdist < -tdist then
    self.territory = 1
  else
    self.territory = 0
  end
end

--------------------------------------------------------------------------------
function track()
  -- Keep holding on our target while we are attacking
  if not world.entityExists(self.target) or (not inSkill() and self.targetHoldTimer <= 0) then
    setTarget(0)
  elseif inSkill() then
    self.targetHoldTimer = config.getParameter("targetHoldTime")
  end

  local doAggroHop = false
  if self.aggressive and self.target == 0 and self.targetSearchTimer <= 0 then
    -- Use either the territorialTargetRadius or the minimalTargetRadius,
    -- depending on whether we are in our territory or not
    local targetId
    if self.territory == 0 then
      targetId = util.closestValidTarget(config.getParameter("territorialTargetRadius"))
    else
      targetId = util.closestValidTarget(config.getParameter("minimalTargetRadius"))
    end

    if targetId ~= 0 then
      -- Pets don't attack npcs unless they are attacking the owner
      if isCaptive() and world.isNpc(targetId) and world.callScriptedEntity(targetId, "attackTargetId") ~= self.ownerEntityId then
        targetId = 0
      end

      setTarget(targetId)
      doAggroHop = true
    end

    self.targetSearchTimer = config.getParameter("targetSearchTime")
  end

  if hasTarget() then
    self.toTarget = entity.distanceToEntity(self.target)
  else
    self.toTarget = {0, 0}
  end

  if doAggroHop then
    faceTarget()
    self.state.pickState({aggroHop=true})
  end

  self.fromTarget = {-self.toTarget[1], -self.toTarget[2]}
end

--------------------------------------------------------------------------------
function hasTarget()
  return self.target ~= 0
end

--------------------------------------------------------------------------------
function setTarget(target)
  if target ~= 0 then
    self.targetHoldTimer = config.getParameter("targetHoldTime")
  end

  self.target = target
end

--------------------------------------------------------------------------------
function setAggressive(enabled, damageOnTouch)
  if enabled then
    monster.setAggressive(true)
    self.aggressive = true
  else
    monster.setAggressive(self.aggressive)
    if not self.aggressive then
      damageOnTouch = false
    end
  end

  if damageOnTouch then
    monster.setDamageOnTouch(true)
    animator.setParticleEmitterActive("damage", true)
  else
    monster.setDamageOnTouch(false)
    animator.setParticleEmitterActive("damage", false)
  end
end

--------------------------------------------------------------------------------
function updateSkillOptions()
  if not hasTarget() then return nil end

  local targetMoveTolerance = 0.5
  local collisionTolerance = 2

  local newTargetPosition = world.entityPosition(self.target)
  local targetMovement = world.distance(self.lastTargetPosition, newTargetPosition)

  if self.noOptionCount > 0 then
    targetMoveTolerance = 0
    if self.staleTargetTimer > 0.1 then
      self.staleTargetTimer = 0.1
    end
  end

  --if target has moved or information is stale, perform full update
  if self.staleTargetTimer <= 0 or math.abs(targetMovement[1]) > targetMoveTolerance or math.abs(targetMovement[2]) > targetMoveTolerance then
    local validOptionCount = 0
    self.skillOptions = {}

    --find starting points and rects for each skill
    for skillName, params in pairs(self.skillParameters) do
      for i, offset in ipairs(self.skillParameters[skillName].approachPoints) do
        local approachPoint = {newTargetPosition[1] + offset[1], newTargetPosition[2] + offset[2]}
        local startRect = translate(self.skillParameters[skillName].startRects[i], newTargetPosition)

        self.skillOptions[#self.skillOptions + 1] = {
          skillName = skillName,
          approachPoint = approachPoint,
          startRect = startRect,
          valid = false
        }

        local approachRect = translate(self.skillParameters[skillName].startRects[i], {0, -offset[2]})
        local groundPoint = findGroundPosition(approachPoint, math.floor(approachRect[2]), math.ceil(approachRect[4]))

        --Test all positions returned by findGroundPosition
        if groundPoint
           and pointWithinRect(groundPoint, startRect) --approachPoint hasn't been shifted out of the startRect
           and (params.requireLos == false or world.lineTileCollision(groundPoint, newTargetPosition) == false) --space is in LoS of target
           and self.skillCooldownTimers[skillName] <= travelTime(world.distance(mcontroller.position(), groundPoint)[1]) + 0.4 --skill will be ready when we get there
            then
          self.skillOptions[#self.skillOptions].approachPoint = groundPoint
          self.skillOptions[#self.skillOptions].valid = true
          validOptionCount = validOptionCount + 1
        end
      end
    end

    if validOptionCount == 0 then
      self.noOptionCount = self.noOptionCount + 1
    else
      self.noOptionCount = 0
    end

    self.lastTargetPosition = newTargetPosition
    self.staleTargetTimer = self.staleTargetTime
  end

  --update deltas, distances and scores
  for _, option in pairs(self.skillOptions) do
    option.approachDelta = world.distance(option.approachPoint, mcontroller.position())
    option.approachDistance = world.magnitude(option.approachDelta)

    --score with custom hook or default method
    if type(_ENV[option.skillName].scoreOption) == "function" then
      option.score = _ENV[option.skillName].scoreOption(option)
    else
      option.score = -option.approachDistance
      if option.valid == false then option.score = -1000 end
    end

    if self.skillChains[option.skillName] then
      option.score = option.score - self.skillChains[option.skillName]
    end
  end

  --rank options
  table.sort(self.skillOptions, function(a,b) return a.score > b.score end)
end

--------------------------------------------------------------------------------
-- adjusts the vec2 or rect by the specified vec2
-- TODO: this should probably be in util
function translate(pointOrRect, offset)
  if #pointOrRect == 4 then
    return {pointOrRect[1] + offset[1], pointOrRect[2] + offset[2], pointOrRect[3] + offset[1], pointOrRect[4] + offset[2]}
  elseif #pointOrRect == 2 then
    return {pointOrRect[1] + offset[1], pointOrRect[2] + offset[2]}
  end
end

--------------------------------------------------------------------------------
-- order the X and Y pairs of a {x1, y1, x2, y2} rect
function normalizeRect(rect)
  if rect[1] > rect[3] then rect[1], rect[3] = rect[3], rect[1] end
  if rect[2] > rect[4] then rect[2], rect[4] = rect[4], rect[2] end
  return rect
end

--------------------------------------------------------------------------------
-- simple inclusion test, requires normalized rect
function pointWithinRect(point, rect)
  local dist1, dist2 = world.distance(point, {rect[1], rect[2]}), world.distance(point, {rect[3], rect[4]})
  return dist1[1] > 0 and dist1[2] > 0 and dist2[1] < 0 and dist2[2] < 0
end

--------------------------------------------------------------------------------
-- draw points and rects for each approach point and valid attack start zone
function debugSkillOptions()
  for i, option in pairs(self.skillOptions) do
    world.debugPoint(option.approachPoint, "green")
    util.debugRect(option.startRect, i == 1 and "#3333FF" or option.valid and "#AAFFBB" or "#FF3333")
    world.debugText(option.skillName, {option.startRect[1], option.startRect[4]}, "#BBBBFF")
    world.debugText(option.approachDelta[1], {option.startRect[1], option.startRect[4] + 1.5}, "#000099")

    world.debugPoint(mcontroller.position(), "blue")
    local tarPos = world.entityPosition(self.target)
    if tarPos then world.debugPoint(tarPos, "red") end
  end
end

--------------------------------------------------------------------------------
function canStartSkill(skillName)
  if skillName and hasTarget() then
    if self.skillCooldownTimers[skillName] <= 0 then
      for _, option in ipairs(self.skillOptions) do
        if option.skillName == skillName and (option.startOnGround == false or mcontroller.onGround()) and pointWithinRect(mcontroller.position(), option.startRect) then
          return true
        end
      end
    end
  end

  return false
end

--------------------------------------------------------------------------------
function canContinueSkill()
  return hasTarget() and
    self.skillTimer > 0
end

--------------------------------------------------------------------------------
function inSkill()
  local stateName = self.state.stateDesc()

  if stateName == nil then
    stateName = ""
  end

  return stateName == "aggroHopState" or isSkillState(stateName)
end

--------------------------------------------------------------------------------
function isSkillState(stateName)
  return string.find(stateName, 'Attack$') or string.find(stateName, 'Special$')
end

--------------------------------------------------------------------------------
function isCaptive()
  return capturepod ~= nil and capturepod.isCaptive()
end

--------------------------------------------------------------------------------
function decrementTimers()
  dt = script.updateDt()

  self.targetSearchTimer = self.targetSearchTimer - dt
  self.jumpTimer = self.jumpTimer - dt
  self.targetHoldTimer = self.targetHoldTimer - dt
  self.skillTimer = self.skillTimer - dt
  self.staleTargetTimer = self.staleTargetTimer - dt
  self.facingTimer = self.facingTimer - dt
  self.jumpCooldown = self.jumpCooldown - dt

  for k,cooldown in pairs(self.skillCooldownTimers) do
    self.skillCooldownTimers[k] = cooldown - dt
  end
end

function setMovementState(running)
  if not mcontroller.onGround() then
    animator.setAnimationState("movement", "jump")
  else
    if running then
      animator.setAnimationState("movement", "run")
    else
      animator.setAnimationState("movement", "walk")
    end
  end
end

function setIdleState()
  if not mcontroller.onGround() then
    animator.setAnimationState("movement", "jump")
  else
    animator.setAnimationState("movement", "idle")
  end
end
