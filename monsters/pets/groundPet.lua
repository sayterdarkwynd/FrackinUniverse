require "/scripts/util.lua"

function init()
  self.pathing = {}
  self.pathing.stuckTimer = 0
  self.pathing.maxStuckTime = 2

  self.jumpCooldown = 0
  self.jumpMaxCooldown = 1

  self.movementParameters = mcontroller.baseParameters()
  self.jumpHoldTime = self.movementParameters.airJumpProfile.jumpHoldTime
  self.jumpSpeed = self.movementParameters.airJumpProfile.jumpSpeed
  self.runSpeed = self.movementParameters.runSpeed

  self.stuckPosition = mcontroller.position()
  self.stuckCount = 0

  self.scriptDelta = 5

  storage.petResources = storage.petResources or config.getParameter("petResources")
  self.petResourceDeltas = config.getParameter("petResourceDeltas")
  setPetResources(storage.petResources)

  local states = stateMachine.scanScripts(config.getParameter("scripts"), "(%a+State)%.lua")
  self.state = stateMachine.create(states)

  local actionStates = {}
  local actions = stateMachine.scanScripts(config.getParameter("scripts"), "(%a+Action)%.lua")
  for _, action in pairs(actions) do
    table.insert(actionStates, 1, action)
  end
  self.actionState = stateMachine.create(actionStates)
  self.autoPickState = false

  self.actionState.leavingState = function(stateName)
    self.querySurroundingsTimer = 0
  end

  self.followTarget = 0

  self.behaviorName = config.getParameter("petBehavior")
  self.behavior = _ENV[self.behaviorName]

  storage.knownPlayers = storage.knownPlayers or config.getParameter("knownPlayers", {})
  storage.foodLikings = storage.foodLikings or config.getParameter("foodLikings", {})

  self.querySurroundingsCooldown = config.getParameter("querySurroundingsCooldown", 3)
  self.querySurroundingsTimer = 1
  self.querySurroundingsRange = config.getParameter("querySurroundingsRange", 50)

  self.standTimer = 0

  self.updateAnchorTimer = 0

  self.debug = false

  if self.behavior and self.behavior.init then
    self.behavior.init()
  end

  self.lastInteract = 0
  monster.setInteractive(false)
end

function receiveNotification(notification)
  return self.state.pickState({ notification = notification })
end


function interact()
  if world.time() - self.lastInteract > config.getParameter("interactCooldown", 3.0) then
    emote("happy")
    self.lastInteract = world.time()
  end
end

function update(dt)
  self.actionState.update(dt)

  if self.actionState.stateDesc() == "" and not self.state.update(dt) then
    self.state.pickState()
  end

  if self.querySurroundingsTimer <= 0 then
    querySurroundings()
    self.querySurroundingsTimer = self.querySurroundingsTimer + self.querySurroundingsCooldown
  end

  tickResources(dt)
  decrementTimers(dt)

  updateAnchor()

  if not self.moved then script.setUpdateDelta(self.scriptDelta) end

  if self.actionState.stateDesc() ~= "" then
    util.debugText(self.actionState.stateDesc(), mcontroller.position(), "blue")
  else
    util.debugText(self.state.stateDesc(), mcontroller.position(), "blue")
  end
  drawDebugResources()
end

function setAnchor(entityId)
  if not self.anchorId or self.anchorId == entityId or not world.entityExists(self.anchorId) then
    storage.anchorPosition = world.entityPosition(entityId)
    self.anchorId = entityId
    world.callScriptedEntity(entityId, "setPet", entity.id(), {
      foodLikings = storage.foodLikings,
      knownPlayers = storage.knownPlayers,
      petResources = petResources(),
      seed = monster.seed()
    })
    return true
  else
    return false
  end
end

function updateAnchor()
  if self.anchorId and world.entityExists(self.anchorId) then
    if self.updateAnchorTimer <= 0 then
      setAnchor(self.anchorId)
      self.updateAnchorTimer = 1
    end
  else
    findAnchor()
  end
end

function findAnchor()
  local anchorName = config.getParameter("anchorName", "humantechstation")
  local nearObjects
  if storage.anchorPosition then
    local nearObjects = world.entityQuery(storage.anchorPosition, 5, {
      includedTypes = { "object" },
      boundMode = "Position"
    })

    for _,objectId in ipairs(nearObjects) do
      local objectPosition = world.entityPosition(objectId)
      if world.entityName(objectId) == anchorName and not world.callScriptedEntity(objectId, "hasPet") then
        setAnchor(objectId)
        return true
      end
    end
  end

  if not storage.home then
    status.setResource("health", 0)
  else
    -- Pet spawned by a colony deed -- allow the pet to continue living until
    -- tenant.despawn kills it.
  end
  return false
end

function querySurroundings()
  local nearEntities = world.entityQuery(mcontroller.position(), self.querySurroundingsRange, {
    includedTypes = { "player", "itemDrop", "monster", "object" },
    withoutEntityId = entity.id()
  })

  --Queue up reactions
  for _,entityId in ipairs(nearEntities) do
    self.behavior.reactTo(entityId)
  end

  --Run actions
  self.behavior.run()

  return false
end

function emote(emoteType)
  animator.burstParticleEmitter("emote"..emoteType)
end

function itemFoodLiking(entityName)
  if not entityName or root.itemType(entityName) ~= "consumable" then
    return false
  end

  local foodLiking = storage.foodLikings[entityName]
  if foodLiking == nil then
    return nil
  end

  --How much does it like the food
  if foodLiking == true or foodLiking == false then
    if foodLiking == true then
      foodLiking = math.random(50, 100)
    elseif foodLiking == false then
      foodLiking = math.random(0, 50)
    end
    storage.foodLikings[entityName] = foodLiking
  end

  return foodLiking
end

function petResources()
  local resources = {}
  for resourceName, resourceValue in pairs(storage.petResources) do
    resources[resourceName] = status.resource(resourceName)
  end
  return resources
end

function setPetResources(resources)
  for resourceName, resourceValue in pairs(resources) do
    status.setResource(resourceName, resourceValue)
  end
end

function tickResources(dt)
  for resourceName, resourceDelta in pairs(self.petResourceDeltas) do
    status.modifyResource(resourceName, resourceDelta * dt)
  end
end

function drawDebugResources()
  if not self.debug then return end

  local resources = storage.petResources
  local position = mcontroller.position()

  local y = 2
  for resourceName, resourceValue in pairs(storage.petResources) do
    --Border
    world.debugLine(vec2.add(position, {-2, y+0.125}), vec2.add(position, {-2, y + 0.75}), "black")
    world.debugLine(vec2.add(position, {-2, y + 0.75}), vec2.add(position, {2, y + 0.75}), "black")
    world.debugLine(vec2.add(position, {2, y + 0.75}), vec2.add(position, {2, y+0.125}), "black")
    world.debugLine(vec2.add(position, {2, y+0.125}), vec2.add(position, {-2, y+0.125}), "black")

    local width = 3.75 * status.resource(resourceName) / 100
    world.debugLine(vec2.add(position, {-1.875, y + 0.25}), vec2.add(position, {-1.875 + width, y + 0.25}), "green")
    world.debugLine(vec2.add(position, {-1.875, y + 0.375}), vec2.add(position, {-1.875 + width, y + 0.375}), "green")
    world.debugLine(vec2.add(position, {-1.875, y + 0.5}), vec2.add(position, {-1.875 + width, y + 0.5}), "green")
    world.debugLine(vec2.add(position, {-1.875, y + 0.625}), vec2.add(position, {-1.875 + width, y + 0.625}), "green")

    world.debugText(resourceName, vec2.add(position, {2.25, y - 0.125}), "blue")
    y = y + 1
  end
end

function decrementTimers(dt)
  self.querySurroundingsTimer = self.querySurroundingsTimer - dt
  self.jumpCooldown = self.jumpCooldown - dt
  self.standTimer = self.standTimer - dt
  self.updateAnchorTimer = self.updateAnchorTimer - dt
end

function setMovementState(running)
  if not mcontroller.onGround() then
    if mcontroller.liquidMovement() then
      animator.setAnimationState("movement", "swim")
    else
      setJumpState()
    end
  else
    if running then
      animator.setAnimationState("movement", "run")
    else
      animator.setAnimationState("movement", "walk")
    end
  end
end

function setIdleState()
  local currentState = animator.animationState("movement")
  if currentState ~= "idle" and currentState ~= "stand" then
    self.standTimer = config.getParameter("idle.standTime", 2)
  end

  if not mcontroller.onGround() then
    setJumpState()
  elseif self.standTimer < 0 then
    animator.setAnimationState("movement", "idle")
  else
    animator.setAnimationState("movement", "stand")
  end
end

function setJumpState()
  if mcontroller.yVelocity() > 0 then
    animator.setAnimationState("movement", "jumping")
  else
    animator.setAnimationState("movement", "falling")
  end
end

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

--------------------------------------------------------------------------------
--MOVEMENT---------------------------------------------------------------------
--------------------------------------------------------------------------------

function approachPoint(dt, targetPosition, stopDistance, running)
  local toTarget = world.distance(targetPosition, mcontroller.position())
  local targetDistance = world.magnitude(targetPosition, mcontroller.position())
  local groundPosition = findGroundPosition(targetPosition, -20, 1, util.toDirection(-toTarget[1]))

  if groundPosition then
    self.approachPosition = groundPosition
  end

  self.pather = self.pather or PathMover:new({run = running})
  self.pather.options.run = running
  if self.approachPosition and (targetDistance > stopDistance or not mcontroller.onGround()) then
    if self.pather:move(self.approachPosition, dt) == "running" then
      mcontroller.controlFace(self.pather.deltaX or toTarget[1])
      setMovementState(running)
    else
      setIdleState()
    end

    return false
  elseif targetDistance <= stopDistance then
    return true
  end
end

--------------------------------------------------------------------------------
function move(direction, options)
  if options == nil then options = {} end
  if options.run == nil then options.run = false end
  direction = util.toDirection(direction)

  local position = mcontroller.position()
  local boundsEdge = 0
  local bounds = boundingBox()
  local tilePosition
  if direction > 0 then
    tilePosition = {math.ceil(position[1]), position[2]}
    boundsEdge = bounds[3]
  else
    tilePosition = {math.floor(position[1]), position[2]}
    boundsEdge = bounds[1]
  end

  --Stop at walls
  if world.lineTileCollision({position[1], position[2] + bounds[2] + 1.5}, { position[1] + boundsEdge + direction, position[2] + bounds[2] + 1.5}, {"Null", "Block", "Dynamic", "Slippery"}) then
    return false, "wall"
  end

  --Check if the position ahead is valid, including slopes
  local yDirs = {0, 1, -1}
  for _,yDir in ipairs(yDirs) do
    if validStandingPosition({tilePosition[1] + direction, tilePosition[2] + yDir}) then
      moveX(direction, options.run)
      return true
    end
  end

  return false, "ledge"
end
