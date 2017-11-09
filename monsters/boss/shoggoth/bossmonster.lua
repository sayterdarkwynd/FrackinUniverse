require("/scripts/vec2.lua")
function init()
  self.tookDamage = false
  self.dead = false
  
  if rangedAttack then
    rangedAttack.loadConfig()
  end

  --Movement
  self.spawnPosition = mcontroller.position()

  self.jumpTimer = 30000 
  self.isBlocked = false
  self.willFall = false
  self.hadTarge = false

  self.queryTargetDistance = config.getParameter("queryTargetDistance", 30)
  self.trackTargetDistance = config.getParameter("trackTargetDistance")
  self.switchTargetDistance = config.getParameter("switchTargetDistance")
  self.keepTargetInSight = config.getParameter("keepTargetInSight", true)

  self.targets = {}

  --Non-combat states
  local states = stateMachine.scanScripts(config.getParameter("scripts"), "(%a+State)%.lua")
  self.state = stateMachine.create(states)

  self.state.leavingState = function(stateName)
    self.state.moveStateToEnd(stateName)
  end

  self.skillParameters = {}
  for _, skillName in pairs(config.getParameter("skills")) do
    self.skillParameters[skillName] = config.getParameter(skillName)
  end

  --Load phases
  self.phases = config.getParameter("phases")
  setPhaseStates(self.phases)

  for skillName, params in pairs(self.skillParameters) do
    if type(_ENV[skillName].onInit) == "function" then
      _ENV[skillName].onInit()
    end
  end

  monster.setDeathParticleBurst("deathPoof")
  monster.setName("The Shoggoth, Formless Horror")
  monster.setDamageBar("special")
end

function update(dt)
  self.tookDamage = false
  world.spawnProjectile("pushzone2",mcontroller.position(),entity.id(),{0,-60},false,params)
  trackTargets(self.keepTargetInSight, self.queryTargetDistance, self.trackTargetDistance, self.switchTargetDistance)

  for skillName, params in pairs(self.skillParameters) do
    if type(_ENV[skillName].onUpdate) == "function" then
      _ENV[skillName].onUpdate(dt)
    end
  end

  if hasTarget() and status.resource("health") > 0 then
    if self.hadTarget == false then
      self.hadTarget = true
    end
    script.setUpdateDelta(1)
    updatePhase(dt)
  else
    if not hasTarget() and status.resource("health") > 0 and self.hadTarget then
      --Lost target, reset boss
      if currentPhase() then
        self.phaseStates[currentPhase()].endState()
      end
      self.hadTarget = false
      self.phase = nil
      self.lastPhase = nil
      setPhaseStates(self.phases)
      --status.setResource("health", status.stat("maxHealth"))

      if bossReset then bossReset() end
    end

    if status.resource("health") > 0 then script.setUpdateDelta(10) end

    if not self.state.update(dt) then
            animator.playSound("turnHostile")
      self.state.pickState()
    end
  end

  self.hadTarget = hasTarget()
end

function damage(args)
  self.tookDamage = true
  self.randval = math.random(100)
  self.randval2 = math.random(100)
  self.healthLevel = status.resource("health") / status.stat("maxHealth")
  self.soundPlay = math.random(2)
  spit1={ power = 0, speed = 15, timeToLive = 0.2 }

  if (self.randval2) >= 80  and (self.healthLevel) <= 0.80 then
    animator.playSound("hurt")
  end  
  
  if (self.randval) >= 99  then
    world.spawnProjectile("shoggothchompexplosion2",mcontroller.position(),entity.id(),{mcontroller.facingDirection(),-20},false,spit1)
    animator.playSound("shoggothChomp")
  end
  
  if (self.randval) >= 99 and (self.healthLevel) <= 0.80 then
    world.spawnProjectile("minishoggothspawn2",mcontroller.position(),entity.id(),{0,2},false,spit1)
    if self.randval >=2 then animator.playSound("giveBirth") end
  elseif (self.randval) >= 99 and (self.healthLevel) <= 0.65 then
    world.spawnProjectile("minishoggothspawn2",mcontroller.position(),entity.id(),{0,2},false,spit1) 
    if self.randval >=2 then animator.playSound("giveBirth") end
    animator.playSound("giveBirth")
  elseif (self.randval) >= 99 and (self.healthLevel) <= 0.50 then
    world.spawnProjectile("minishoggothspawn2",mcontroller.position(),entity.id(),{0,2},false,spit1) 
    if self.randval >=2 then animator.playSound("giveBirth") end
    animator.playSound("giveBirth")
  end
  
  if status.resource("health") <= 0 then
    local inState = self.state.stateDesc()
    animator.playSound("deathPuff")
    if inState ~= "dieState" and not self.state.pickState({ die = true }) then
      self.state.endState()
      self.dead = true
    end
  end

  if args.sourceId and args.sourceId ~= 0 and not inTargets(args.sourceId) then
    table.insert(self.targets, args.sourceId)
  end
end

function shouldDie()
  return self.dead
end

function hasTarget()
  if self.targetId and self.targetId ~= 0 then
    return self.targetId
  end
  return false
end

function trackTargets(keepInSight, queryRange, trackingRange, switchTargetDistance)
  if keepInSight == nil then keepInSight = true end

  if self.targetId == nil then
    table.insert(self.targets, util.closestValidTarget(queryRange))
  end

  --Move the closest target to the top of the list if it's inside the target switch range
  if switchTargetDistance then
    local closestValid = util.closestValidTarget(switchTargetDistance)
    local i = inTargets(closestValid)
    if i then table.remove(self.targets, i) end
    table.insert(self.targets, 1, closestValid)
  end

  --Remove any invalid targets from the list
  local updatedTargets = {}
  for i,targetId in ipairs(self.targets) do
    if validTarget(targetId, keepInSight, trackingRange) then
      table.insert(updatedTargets, targetId)
    end
  end
  self.targets = updatedTargets

  --Set target to be top of the list
  self.targetId = self.targets[1]
  if self.targetId then
    self.targetPosition = world.entityPosition(self.targetId)
  end
end

function validTarget(targetId, keepInSight, trackingRange)
  local entityType = world.entityType(targetId)
  if entityType ~= "player" and entityType ~= "npc" then
    status.addEphemeralEffect("invulnerable",math.huge)
    return false
  end

  if not world.entityExists(targetId) then 
    status.addEphemeralEffect("invulnerable",math.huge)
    return false 
  end

  if keepInSight and not entity.entityInSight(targetId) then 
    status.addEphemeralEffect("invulnerable",math.huge)  
    return false 
  end

  if trackingRange then
    local distance = world.magnitude(mcontroller.position(), world.entityPosition(targetId))
    if distance > trackingRange then 
      status.addEphemeralEffect("invulnerable",math.huge)
      return false 
    end
  end
  status.removeEphemeralEffect("invulnerable")
  return true
end 

function inTargets(entityId)
  for i,targetId in ipairs(self.targets) do
    if targetId == entityId then
      return i
    end
  end
  return false
end

--PHASES-----------------------------------------------------------------------

function currentPhase()
  return self.phase
end

function updatePhase(dt)
  if not self.phase then
    self.phase = 1
  end

  --Check if next phase is ready
  local nextPhase = self.phases[self.phase + 1]
  if nextPhase then
    if nextPhase.trigger and nextPhase.trigger == "healthPercentage" then
      if status.resourcePercentage("health") < nextPhase.healthPercentage then
        self.phase = self.phase + 1
      end
    end
  end

  if not self.lastPhase or self.lastPhase ~= self.phase then
    if self.lastPhase then
      self.phaseStates[self.lastPhase].endState()
    end
    self.phaseStates[currentPhase()].pickState({enteringPhase = currentPhase()})
  end
  if not self.phaseStates[currentPhase()].update(dt) then
    self.phaseStates[currentPhase()].pickState()
  end

  self.lastPhase = self.phase
end

function setPhaseStates(phases)
  self.phaseSkills = {}
  self.phaseStates = {}
  for i,phase in ipairs(phases) do
    self.phaseSkills[i] = {}
    for _,skillName in ipairs(phase.skills) do
      table.insert(self.phaseSkills[i], skillName)
    end
    if phase.enterPhase then
      table.insert(self.phaseSkills[i], 1, phase.enterPhase)
      animator.playSound("attackMain")
    end
    self.phaseStates[i] = stateMachine.create(self.phaseSkills[i])

    --Cycle through the skills
    self.phaseStates[i].leavingState = function(stateName)
      self.phaseStates[i].moveStateToEnd(stateName)
    end
  end
end

--MOVEMENT---------------------------------------------------------------------

function boundingBox(force)
  if self.boundingBox and not force then return self.boundingBox end

  local collisionPoly = mcontroller.collisionPoly()
  local bounds = {0, 0, 0, 0}

  for _,point in pairs(collisionPoly) do
    if point[1] < bounds[1] then bounds[1] = point[1] end
    if point[2] < bounds[2] then bounds[2] = point[2] end
    if point[1] > bounds[3] then bounds[3] = point[1] end
    if point[2] > bounds[4] then bounds[4] = point[2] end
  end
  self.boundingBox = bounds

  return bounds
end

function checkWalls(direction)
  local bounds = boundingBox()
  local position = mcontroller.position()

  local lineStart = {position[1], position[2]}

  if direction < 0 then
    lineStart[1] = lineStart[1] + bounds[1]
  else
    lineStart[1] = lineStart[1] + bounds[3]
  end

  local lineEnd = {lineStart[1] + direction * 3, lineStart[2]}

  return world.lineTileCollision(lineStart, lineEnd, {"Null", "Block", "Dynamic"})
end

function flyTo(position, speed)
  if not speed then speed = mcontroller.baseParameters().flySpeed end
  local toPosition = vec2.norm(world.distance(position, mcontroller.position()))
  mcontroller.controlFly(vec2.mul(toPosition, speed))
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
        mcontroller.controlJump()
      end
    end
  end

  if delta[2] < 0 then
    mcontroller.controlDown()
  end
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
end

--------------------------------------------------------------------------------
function isBlocked()
  return self.isBlocked
end

--------------------------------------------------------------------------------
function willFall()
  return self.willFall
end

function waitforseconds(seconds)
  local start = os.time()
  repeat until os.time() > start + seconds
end

