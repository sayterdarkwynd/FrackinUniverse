require "/scripts/util.lua"

function init()
  self.groundDirection = { 0, -1 }
  self.groundChangeCooldownTimer = 0

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

  self.isBlocked = false
  self.willFall = false

  self.jumpTimer = 0

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

  animator.setAnimationState("movement", "idle")
  monster.setDeathParticleBurst("deathPoof")

  self.debug = false
end

--------------------------------------------------------------------------------
function update(dt)
  if self.groundDirection[2] ~= -1 and (onGround() or self.groundChangeCooldownTimer > 0) then
    mcontroller.controlFly({0,0})
    mcontroller.controlParameters({
      gravityEnabled = false
    })
  end

  self.position = mcontroller.position()
  self.onGround = mcontroller.onGround()

  if storage.basePosition == nil then
    storage.basePosition = self.position
  end

  local inState = self.state.stateDesc()

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
    drawDebugSkillOptions()
  end

  if hasTarget() then
    setGroundDirection({0, -1})
  end

  decrementTimers()

  script.setUpdateDelta(hasTarget() and 1 or 10)
end

--------------------------------------------------------------------------------
-- get the skill parameters from the relevant configParameter and make necessary adjustments
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
      if args.sourceId ~= self.target and args.sourceId ~= 0 then setTarget(args.sourceId) end
    end
  end
end

--------------------------------------------------------------------------------
function setGroundDirection(groundDirection, immediateRotation)
  if immediateRotation == nil then immediateRotation = false end

  self.groundDirection = groundDirection
  self.groundChangeCooldownTimer = config.getParameter("changeGroundCooldown")

  local desiredAngle = math.atan(self.groundDirection[2], self.groundDirection[1]) + math.pi / 2
  animator.rotateGroup("all", -mcontroller.facingDirection() * desiredAngle, immediateRotation)

  return true
end

--------------------------------------------------------------------------------
function headingFromDirection(direction)
  return {
    direction * -self.groundDirection[2],
    direction * self.groundDirection[1]
  }
end

--------------------------------------------------------------------------------
function boundingBox()
  local position = mcontroller.position()
  local bounds = config.getParameter("metaBoundBox")
  bounds[1] = position[1] + bounds[1]
  bounds[2] = position[2] + bounds[2]
  bounds[3] = position[1] + bounds[3]
  bounds[4] = position[2] + bounds[4]
  return bounds
end

--------------------------------------------------------------------------------
function onGround()
  if self.jumping then return false end

  local bounds = boundingBox()

  local floorCheckRegion = {
    bounds[1] + self.groundDirection[1] * 0.5,
    bounds[2] + self.groundDirection[2] * 0.5,
    bounds[3] + self.groundDirection[1] * 0.5,
    bounds[4] + self.groundDirection[2] * 0.5
  }
  return world.rectTileCollision(floorCheckRegion, {"Null", "Block", "Dynamic"})
end

--------------------------------------------------------------------------------
function controlFace(direction)
  mcontroller.controlFace(1)
  if direction < 0 then
    animator.setGlobalTag("flipTag", "?flipx")
  else
    animator.setGlobalTag("flipTag", "")
  end
end

--------------------------------------------------------------------------------
function faceTarget()
  if self.onGround then
    mcontroller.controlFace(self.toTarget[1])
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
function travelTime(distance)
  local runSpeed = mcontroller.baseParameters().runSpeed
  return math.abs(distance / runSpeed)
end

--------------------------------------------------------------------------------
function crawl(direction, run)
  local bounds = boundingBox()
  local heading = headingFromDirection(direction)

  controlFace(direction)

  -- Check for concave ground transitions
  heading = concaveGroundTransition(heading, direction)

  -- Check for convex ground transitions
  heading = convexGroundTransition(heading, direction)

  --Just move like a normal ground monster if on normal ground
  if self.groundDirection[2] == -1 and math.abs(direction) > 0 then
    if onGround() then animator.setAnimationState("movement", "walk") end
    mcontroller.controlMove(direction, run)
  end

  local movementParameters = mcontroller.baseParameters()

  local moveSpeed = movementParameters.walkSpeed
  if run then moveSpeed = movementParameters.runSpeed end
  if self.groundDirection[1] ~= 0 then
    moveSpeed = moveSpeed * config.getParameter("wallWalkSpeedMultiplier")
  end

  if self.groundChangeCooldownTimer > 0 then
    moveSpeed = moveSpeed * config.getParameter("cornerWalkSpeedMultiplier")
  end

  --util.debugLine(mcontroller.position(), vec2.add(mcontroller.position(), vec2.mul(self.groundDirection, 3)), "blue")
  util.debugLine(mcontroller.position(), vec2.add(mcontroller.position(), vec2.mul(heading, 3)), "green")

  if math.abs(direction) > 0 or true then
    local movement = vec2.mul(heading, moveSpeed)
    movement = vec2.add(movement, vec2.mul(self.groundDirection, toGroundMovementMultiplier(heading) * moveSpeed))

    util.debugLine(mcontroller.position(), vec2.add(mcontroller.position(), movement), "blue")

    if onGround() then animator.setAnimationState("movement", "walk") end
    mcontroller.controlFly(movement, false)
    return true
  else
    animator.setAnimationState("movement", "idle")
  end
end

function toGroundMovementMultiplier(heading)
  local bounds = boundingBox()

  local toGroundMovementMultiplier = config.getParameter("toGroundMovementMultiplier") or 0.5

  if self.groundChangeCooldownTimer <= 0 then
    -- Push away from the ground a bit if blocked by a one-block-high step
    local stepCheckRegion = {
      bounds[1] + heading[1] * 0.5,
      bounds[2] + heading[2] * 0.5,
      bounds[3] + heading[1] * 0.5,
      bounds[4] + heading[2] * 0.5
    }
    if self.groundDirection[1] < 0 then stepCheckRegion[3] = stepCheckRegion[3] - 1.5 end
    if self.groundDirection[1] > 0 then stepCheckRegion[1] = stepCheckRegion[1] + 1.5 end
    if self.groundDirection[2] < 0 then stepCheckRegion[4] = stepCheckRegion[4] - 1.5 end
    if self.groundDirection[2] > 0 then stepCheckRegion[2] = stepCheckRegion[2] + 1.5 end

    if world.rectTileCollision(stepCheckRegion, {"Null", "Block", "Dynamic"}) then
      util.debugRect(stepCheckRegion, "red")
      toGroundMovementMultiplier = -0.1
    else
      util.debugRect(stepCheckRegion, "green")
    end
  end

  return toGroundMovementMultiplier
end
--Alias for move
moveX = move

--Check if we have hit a wall, and walk up on it
function concaveGroundTransition(heading, direction)
  local bounds = boundingBox()

  local wallCheckRegion = {
    bounds[1] + heading[1] + 0.125,
    bounds[2] + heading[2] + 0.125,
    bounds[3] + heading[1] - 0.125,
    bounds[4] + heading[2] - 0.125
  }
  -- Walls must be higher than one block off the ground
  if self.groundDirection[1] < 0 then wallCheckRegion[1] = wallCheckRegion[1] + 1.0 end
  if self.groundDirection[1] > 0 then wallCheckRegion[3] = wallCheckRegion[3] - 1.0 end
  if self.groundDirection[2] < 0 then wallCheckRegion[2] = wallCheckRegion[2] + 1.0 end
  if self.groundDirection[2] > 0 then wallCheckRegion[4] = wallCheckRegion[4] - 1.0 end

  if world.rectTileCollision(wallCheckRegion, {"Null", "Block", "Dynamic"}) then
    if setGroundDirection(heading) then
      util.debugLog("hit wall at %s", heading)
      heading = headingFromDirection(direction)
    end
  end

  return heading
end

function jump()
  if mcontroller.onGround() then
    mcontroller.controlJump()
  end
end

--------------------------------------------------------------------------------
function move(delta, run, jumpThresholdX)
  checkTerrain(delta[1])

  mcontroller.controlMove(delta[1], run)

  if self.jumpTimer > 0 and not self.onGround then
    mcontroller.controlHoldJump()
  else
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
        self.jumpTimer = util.randomInRange(config.getParameter("jumpTime"))
        jump()
      end
    end
  end

  if delta[2] < 0 then
    mcontroller.controlDown()
  end

  if not self.onGround then
    animator.setAnimationState("movement", "jump")
  elseif delta[1] ~= 0 then
    animator.setAnimationState("movement", "run")
  else
    animator.setAnimationState("movement", "idle")
  end
end
--------------------------------------------------------------------------------
function controlJump()
  if mcontroller.onGround() then
    mcontroller.controlJump()
  end
end

--------------------------------------------------------------------------------
function moveX(direction, run)
  checkTerrain(direction)

  mcontroller.controlMove(direction, run)
end
--------------------------------------------------------------------------------

--Check if we have hit a ledge, and walk over it
function convexGroundTransition(heading, direction)
  local bounds = boundingBox()

  local floorCheckRegion = {
    bounds[1] + self.groundDirection[1] * 1.25,
    bounds[2] + self.groundDirection[2] * 1.25,
    bounds[3] + self.groundDirection[1] * 1.25,
    bounds[4] + self.groundDirection[2] * 1.25
  }
  if not world.rectTileCollision(floorCheckRegion, {"Null", "Block", "Dynamic"}) then
    local newGroundDirection = { -heading[1], -heading[2] }
    local convexCheckRegion = {
      floorCheckRegion[1] + newGroundDirection[1] * 1.125,
      floorCheckRegion[2] + newGroundDirection[2] * 1.125,
      floorCheckRegion[3] + newGroundDirection[1] * 1.125,
      floorCheckRegion[4] + newGroundDirection[2] * 1.125
    }
    if world.rectTileCollision(convexCheckRegion, {"Null", "Block", "Dynamic"}) then
      if setGroundDirection(newGroundDirection) then
        util.debugLog("convex at %s", heading)
        heading = headingFromDirection(direction)
      end
    else
      --Falling
      setGroundDirection({ 0, -1 })
      heading = headingFromDirection(direction)
      animator.setAnimationState("movement", "jump")
      util.debugLog("falling at %s", heading)
    end
  end

  return heading
end


--------------------------------------------------------------------------------
--TODO: this could probably be further optimized by creating a list of discrete points and using sensors... project for another time
function checkTerrain(direction)
  --normalize to 1 or -1
  direction = direction > 0 and 1 or -1

  local reverse = false
  if direction ~= nil then
    reverse = direction ~= mcontroller.facingDirection()
  end

  local boundBox = mcontroller.boundBox()

  -- update self.isBlocked
  local blockLine, topLine
  if not reverse then
    blockLine = {monster.toAbsolutePosition({boundBox[3] + 0.25, boundBox[4]}), monster.toAbsolutePosition({boundBox[3] + 0.25, boundBox[2] - 1.0})}
  else
    blockLine = {monster.toAbsolutePosition({-boundBox[3] - 0.25, boundBox[4]}), monster.toAbsolutePosition({-boundBox[3] - 0.25, boundBox[2] - 1.0})}
  end

  local blockBlocks = world.collisionBlocksAlongLine(blockLine[1], blockLine[2])
  self.isBlocked = false
  if #blockBlocks > 0 then
    --check for basic blockage
    local topOffset = blockBlocks[1][2] - blockLine[2][2]
    if topOffset > 2.75 then
      self.isBlocked = true
    elseif topOffset > 0.25 then
      --also check for that stupid little hook ledge thing
      self.isBlocked = not world.pointTileCollision({blockBlocks[1][1] - direction, blockBlocks[1][2] - 1})

      if not self.isBlocked then
        --also check if blocks above prevent us from climbing
        topLine = {monster.toAbsolutePosition({boundBox[1], boundBox[4] + 0.5}), monster.toAbsolutePosition({boundBox[3], boundBox[4] + 0.5})}
        self.isBlocked = world.lineTileCollision(topLine[1], topLine[2])
      end
    end
  end

  -- util.debugLine(blockLine[1], blockLine[2], self.isBlocked and "red" or "blue")
  -- if topLine then util.debugLine(topLine[1], topLine[2], self.isBlocked and "red" or "blue") end
  -- if #blockBlocks > 0 then world.debugPoint({blockBlocks[1][1] - direction, blockBlocks[1][2] - 1}, self.isBlocked and "red" or "blue") end

  -- update self.willFall
  local fallLine
  if reverse then
    fallLine = {monster.toAbsolutePosition({-0.5, boundBox[2] - 0.75}), monster.toAbsolutePosition({boundBox[3], boundBox[2] - 0.75})}
  else
    fallLine = {monster.toAbsolutePosition({0.5, boundBox[2] - 0.75}), monster.toAbsolutePosition({-boundBox[3], boundBox[2] - 0.75})}
  end
  self.willFall =
      world.lineTileCollision(fallLine[1], fallLine[2]) == false and
      world.lineTileCollision({fallLine[1][1], fallLine[1][2] - 1}, {fallLine[2][1], fallLine[2][2] - 1}) == false

  -- util.debugLine(fallLine[1], fallLine[2], self.willFall and "red" or "blue")
  -- util.debugLine({fallLine[1][1], fallLine[1][2] - 1}, {fallLine[2][1], fallLine[2][2] - 1}, self.willFall and "red" or "blue")
end

--------------------------------------------------------------------------------
function isBlocked()
  return self.isBlocked
end

--------------------------------------------------------------------------------
function willFall()
  return self.willFall
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
    end

    self.targetSearchTimer = config.getParameter("targetSearchTime")
  end

  if hasTarget() then
    self.toTarget = entity.distanceToEntity(self.target)
  else
    self.toTarget = {0, 0}
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

        approachPoint = world.resolvePolyCollision(config.getParameter("movementSettings.collisionPoly"), approachPoint, collisionTolerance)
        if approachPoint
           and pointWithinRect(approachPoint, startRect) --approachPoint hasn't been shifted out of the startRect
           and (params.requireLos == false or world.lineTileCollision(approachPoint, newTargetPosition) == false) --space is in LoS of target
           and self.skillCooldownTimers[skillName] <= travelTime(world.distance(mcontroller.position(), approachPoint)[1]) + 0.4 --skill will be ready when we get there
            then

          --now check for ground below. first try a line down from the approach point
          local canStand = world.lineTileCollision(approachPoint, {approachPoint[1], startRect[2] + mcontroller.boundBox()[2]}, {"Null", "Block", "Dynamic", "Platform"})

          --if that fails, try placing a collision poly at the bottom edge of the startRect
          if not canStand then
            local fallPoint = {approachPoint[1], startRect[2]}
            local resolvedFallPoint = world.resolvePolyCollision(config.getParameter("movementSettings.collisionPoly"), fallPoint, collisionTolerance)

            if (resolvedFallPoint == nil) or math.abs(fallPoint[2] - resolvedFallPoint[2]) > 0.2 then
              if resolvedFallPoint and pointWithinRect(resolvedFallPoint, startRect) then approachPoint = resolvedFallPoint end
              canStand = true
            end
          end

          if canStand then
            self.skillOptions[#self.skillOptions].approachPoint = approachPoint
            self.skillOptions[#self.skillOptions].valid = true
            validOptionCount = validOptionCount + 1
          end
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
function drawDebugSkillOptions()
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

  return isSkillState(stateName)
end

--------------------------------------------------------------------------------
function isSkillState(stateName)
  return string.find(stateName, 'Attack$') or string.find(stateName, 'Special$')
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
  self.groundChangeCooldownTimer = self.groundChangeCooldownTimer - dt

  for k,cooldown in pairs(self.skillCooldownTimers) do
    self.skillCooldownTimers[k] = cooldown - dt
  end
end

function attacking()
  return isSkillState(self.state.stateDesc())
end
