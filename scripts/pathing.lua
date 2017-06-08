require "/scripts/util.lua"
require "/scripts/rect.lua"
require "/scripts/pathutil.lua"

--------------------------------------------------------------------------------
function moveX(direction, run)
  mcontroller.controlMove(direction, run)
end

PathFinder = {}
function PathFinder:new(options)
  newFinder = {
   edges = {},
   options = options,
   stuckTimer = 0
  }
  setmetatable(newFinder, extend(self))
  return newFinder
end

function PathFinder:find(targetPosition)
  if not self:canPathfind() then
    return "pathfinding"
  end

 if not self.hasPath and not self.aStar then
    if self.options.mustEndOnGround and not validStandingPosition(targetPosition, false) then
      return false
    end

    self:reset()
    self:start(mcontroller.position(), targetPosition)
  end
  return self:explore()
end

function PathFinder:start(sourcePosition, targetPosition)
  self.target = targetPosition

  local baseParameters = mcontroller.baseParameters()
  local jumpSpeed = baseParameters.airJumpProfile.jumpSpeed
  jumpSpeed = jumpSpeed + (jumpSpeed * status.stat("jumpModifier"))
  baseParameters.airJumpProfile.jumpSpeed = jumpSpeed

  self.aStar = world.platformerPathStart(sourcePosition, self.target, baseParameters, self.options)
end

function PathFinder:canPathfind()
  return mcontroller.onGround() or not mcontroller.baseParameters().gravityEnabled
end

function PathFinder:exploreRate()
  local fidelityOptions = {
    minimum = 25,
    low = 50,
    medium = 100,
    high = 150
  }
  if world.fidelity then
    return fidelityOptions[world.fidelity()]
  else
    return fidelityOptions.high
  end
end

function PathFinder:explore()
  local result = self.aStar:explore(self:exploreRate())
  if result == true and self:canPathfind() then
    self.edges = self.aStar:result()
    self.hasPath = true
    self.currentEdgeIndex = 1
    self.lastEdgeIndex = 1
    self.stuckTimer = 0
    self.aStar = nil
    return true
  elseif result == false then
    self.aStar = nil
    return false
  end
  util.debugText("Looking for path", vec2.add(mcontroller.position(), {0, -1}), "yellow")
  return "pathfinding"
end

function PathFinder:reset()
  self.edges = {}
  self.hasPath = false
  self.currentEdgeIndex = 1
end

function PathFinder:currentEdge()
  return self.edges[self.currentEdgeIndex]
end

function PathFinder:lookAhead(i)
  return self.edges[self.currentEdgeIndex + i]
end

function PathFinder:update(targetPosition)
  -- Reset path if it's been stuck on the same node for a bit
 if self.hasPath and self.stuckTimer > 0.5 then
    self:reset()
  end
  self.stuckTimer = self.stuckTimer + script.updateDt()

  --Replace current path
  if self.target and world.magnitude(targetPosition, self.target) > 2 then
    --self:start(mcontroller.position(), targetPosition)
    self:reset()
  end

  -- Find a new path if none exists
  if not self.hasPath then
    local findProgress = self:find(targetPosition)
    if findProgress == true then
      return "running"
    end
    return findProgress
  end

  if self.aStar then
    if self:explore() == false then
      return false
    end
  end

  if self.currentEdgeIndex > #self.edges then
    self:reset()
    return false
  end

  if self.hasPath then
    if self.currentEdgeIndex ~= self.lastEdgeIndex then
      self.stuckTimer = 0
      self.lastEdgeIndex = self.currentEdgeIndex
    end
    return "running" -- Still have a path, therefore we've not arrived yet.
  else
    return true -- Arrived at the destination
  end
end

function PathFinder:advance()
  self.currentEdgeIndex = self.currentEdgeIndex + 1
end

PathMover = {}
function PathMover:new(options)
  options = options or {}
  local newPather = {}
  local pathOptions = applyDefaults(options.pathOptions or {}, {
    returnBest = false,
    mustEndOnGround = mcontroller.baseParameters().gravityEnabled,
    maxDistance = 200,
    swimCost = 5,
    dropCost = 2,
    boundBox = mcontroller.boundBox(),
    droppingBoundBox = padBoundBox(0.2, 0), --Wider bound box for dropping
    standingBoundBox = padBoundBox(-0.7, 0), --Thinner bound box for standing and landing
    smallJumpMultiplier = 1 / math.sqrt(2), -- 0.5 multiplier to jump height
    jumpDropXMultiplier = 1,
    enableWalkSpeedJumps = true,
    enableVerticalJumpAirControl = false,
    maxFScore = 400,
    maxNodesToSearch = 70000,
    maxLandingVelocity = -10.0,
    liquidJumpCost = 15
  })
  newPather.finder = PathFinder:new(pathOptions)

 newPather.options = applyDefaults(options, {
    run = false,
    movementParameters = {}
  })
  newPather.deltaX = mcontroller.facingDirection()

  newPather.onGround = mcontroller.onGround()
  newPather.position = mcontroller.position()
  newPather.lastPosition = newPather.position

  newPather.boundBox = mcontroller.boundBox()
  
  newPather.canOpenDoors = config.getParameter("pathing.canOpenDoors", false)
  newPather.forceWalkingBackwards = config.getParameter("pathing.forceWalkingBackwards", false)
  
  setmetatable(newPather, extend(self))
  return newPather
end

function PathMover:move(targetPosition, dt)
  local run = self.options.run
  if self.forceWalkingBackwards then
    if run == true then run = mcontroller.movingDirection() == mcontroller.facingDirection() end
  end

  self.lastPosition = self.position
  self.position = mcontroller.position()
  self.run = run
  self.targetPosition = targetPosition
  self.targetDistance = world.magnitude(targetPosition, self.position)
  self.toTarget = world.distance(targetPosition, self.position)
  self.dt = dt

  if self.jumpCooldown then
    self.jumpCooldown = self.jumpCooldown - dt
    if self.jumpCooldown <= 0 then self.jumpCooldown = nil end
  end
  self.onGround = mcontroller.onGround()

  if self.onGround and self.targetDistance < 2 and math.abs(self.toTarget[2]) < 1 then
    return self:approachTargetPosition()
  end

  if self.downHoldTimer ~= nil then
    self:keepDropping(dt)
    return "running"
  end

  local result = self.finder:update(self.targetPosition)
  if result ~= "running" then
    return result
  end

  debugPath(self.finder)

  self.controlParameters = copy(self.options.movementParameters)
  local result = self:edgeMove()
  mcontroller.controlParameters(self.controlParameters)

  return result
end

function PathMover:approachTargetPosition()
  if math.abs(self.toTarget[1]) < self:tickMoveDistance() and math.abs(self.toTarget[2]) < 1 then
    mcontroller.setXVelocity(0)
    return true
  else
    moveX(self.toTarget[1], self.run)
    return "running"
  end
end


function PathMover:advancePath()
  self.finder:advance()
  self:updateEdge()
end

function PathMover:tickMoveDistance()
  return 0.5
end

function PathMover:updateEdge()
  self.edge = self.finder:currentEdge()
  if self.edge then
    self.nextPathPosition = self.edge.target.position
    self.action = self.edge.action
    self.delta = world.distance(self.nextPathPosition, self.position)
  end
end

function PathMover:edgeMove()
  setMoved(true)

  self:updateEdge()

  if self.edge == nil then return true end
  
  if not self:openDoors() then
    return false
  end

  if self.action == "Swim" then
    return self:moveSwim()
  elseif self.action == "Jump" then
    return self:moveJump()
  elseif self.action == "Drop" then
    return self:moveDrop()
  elseif self.action == "Arc" then
    return self:moveArc()
  elseif self.action == "Land" then
    return self:moveLand()
  elseif self.action == "Walk" then
    return self:moveWalk()
  elseif self.action == "Fly" then
    return self:moveFly()
  end
end

function PathMover:openDoors()
  local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())
  
  if util.toDirection(self.delta[1]) > 0 then
    bounds[1] = bounds[3]
    bounds[3] = bounds[3] + 1
  else
    bounds[3] = bounds[1]
    bounds[1] = bounds[1] - 1
  end

  if world.rectTileCollision(bounds, {"Dynamic"}) then
    -- There is a colliding object in the way. See if we can open it
   local closedDoorIds = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "closedDoor" } })
    if #closedDoorIds == 0 or not self.canOpenDoors then
      return false
    else
      for _, closedDoorId in pairs(closedDoorIds) do
        if self.options.openDoorCallback == nil or self.options.openDoorCallback(closedDoorId) then
          world.callScriptedEntity(closedDoorId, "openDoor")
        end
      end
    end
  end
  return true
end

function PathMover:timedDrop(time)
  if holdTime == nil then holdTime = 0 end
  holdTime = math.min(holdTime, 0.5)
  mcontroller.controlDown()
  self.downHoldTimer = holdTime
end

function PathMover:keepDropping(dt)
  if self.downHoldTimer ~= nil then
    mcontroller.controlDown()

    self.downHoldTimer = self.downHoldTimer - dt
    if self.downHoldTimer <= 0 or mcontroller.onGround() then
      self.downHoldTimer = nil
    end
  end
end

function PathMover:moveSwim()
  self.deltaX = self.delta[1]
  mcontroller.controlApproachVelocity(vec2.mul(vec2.norm(self.delta), mcontroller.baseParameters().walkSpeed), mcontroller.baseParameters().liquidJumpProfile.jumpControlForce)

  if passedTarget(self.edge) then
    self:advancePath()
  end
  return "running"
end

function PathMover:moveJump()
  if mcontroller.onGround() and self.jumpCooldown then
    return "running"
  end

  if world.magnitude(mcontroller.position(), self.edge.source.position) < 1.0 then
    if not self.jumpTimer then
      self.jumpTimer = 0.2
      mcontroller.setPosition(self.edge.source.position)
      mcontroller.setVelocity({0,0})
    end
    self.deltaX = self.edge.jumpVelocity[1]

    if mcontroller.liquidMovement() or self.jumpTimer <= 0 then
      --Try to not get slowed down by friction
      self.controlParameters.airFriction = 0
      self.controlParameters.liquidFriction = 0
      self.controlParameters.liquidImpedance = 0
      self.controlParameters.groundFriction = 0

      --Approach the jump position more precisely to follow the jump arc accurately
      mcontroller.setVelocity({self.edge.jumpVelocity[1], self.edge.jumpVelocity[2]})
      self.jumpTimer = nil
      self:advancePath()
    else
      self.jumpTimer = self.jumpTimer - script.updateDt()
    end
  end

  return "running"
end

function PathMover:moveDrop()
  if math.abs(self.delta[1]) > self:tickMoveDistance() then
    moveX(self.delta[1], false)
    return "running"
  end

  mcontroller.setPosition({self.nextPathPosition[1], self.position[2]})
  self:timedDrop(math.max(timeToFall(-self.delta[2]), 0.05))
  mcontroller.setXVelocity(0)
  self:advancePath()
  return "running"
end

function PathMover:moveArc()
  self.jumped = false
  self.jumpCooldown = 0.3

  -- Advance path if the target position is in a different direction than the arc is pointing
  while self.edge and self.edge.action == "Arc" do
    if passedTarget(self.edge) then
      self:advancePath()
    else
      break
    end
  end
  if not self.edge or self.edge.action ~= "Arc" then return "running" end

  if mcontroller.onGround() and not mcontroller.liquidMovement() then
    local nextEdge = self.finder:lookAhead(1) or {}
    if nextEdge.action and nextEdge.action ~= "Arc" then
      self.arcDelta = nil
      self:advancePath()
    else
      self.arcDelta = self.arcDelta or self.delta[1]
      moveX(self.arcDelta, run)
      self.deltaX = self.arcDelta
    end
    return "running"
  else
    self.arcDelta = nil
    --Try to not get slowed down by friction
    self.controlParameters.airFriction = 0
    self.controlParameters.liquidFriction = 0
    self.controlParameters.liquidImpedance = 0
    self.controlParameters.groundFriction = 0

    local velocity = self.edge.source.velocity or self.edge.target.velocity or {0,0}
    -- setXVelocity in case that changes mid-jump (e.g. when jumping straight
    -- up and then to the side).
    mcontroller.controlApproachXVelocity(velocity[1], mcontroller.baseParameters().groundForce)

    if mcontroller.liquidMovement() then
      if velocity[2] ~= 0 then
        mcontroller.controlApproachYVelocity(velocity[2], mcontroller.baseParameters().airJumpProfile.jumpControlForce)
      else
        self:advancePath()
      end
    end

    return "running"
  end
end

function PathMover:moveLand()
  if (mcontroller.onGround() or (mcontroller.liquidMovement() and math.abs(self.delta[2]) < 1)) and math.abs(self.delta[1]) < 1 then
    self:advancePath()
    mcontroller.controlApproachXVelocity(0, mcontroller.baseParameters().groundForce)
  end
  return "running"
end

function PathMover:moveWalk()
  while self.edge and self.edge.action == "Walk" do
    if passedTarget(self.edge) then
      if self.edge.target.velocity then
        mcontroller.setVelocity(self.edge.target.velocity)
      end
      self:advancePath()
    else
      break
    end
  end

  if self.edge and self.edge.action == "Walk" then
    local run = self.run
    for i = 1, 5 do
      if run then break end
      local edge = self.finder:lookAhead(i)
      if edge and edge.action == "Walk" then
        if edge.target.velocity and math.abs(edge.target.velocity[1]) > mcontroller.baseParameters().walkSpeed then
          run = true
        end
      else
        break
      end
    end

    local edgeDelta = world.distance(self.edge.target.position, self.edge.source.position)
    moveX(edgeDelta[1], run)
    self.deltaX = self.delta[1]
  end
  return "running"
end

function PathMover:moveFly()
  while self.edge and self.edge.action == "Fly" do
    if passedTarget(self.edge) then
      self:advancePath()
    else
      break
    end
  end

  if self.edge and self.edge.action == "Fly" then
    mcontroller.controlFly(self.delta)
    self.deltaX = self.delta[1]
  end
  return "running"
end

function passedTargetOnAxis(edge, axis)
  local edgeDistance = world.distance(edge.target.position, edge.source.position)
  local targetDistance = world.distance(edge.target.position, mcontroller.position())
  return edgeDistance[axis] ~= 0 and edgeDistance[axis] * targetDistance[axis] < 0
end

function passedTarget(edge)
  return passedTargetOnAxis(edge, 1) or passedTargetOnAxis(edge, 2)
end

--JUMPING AND DROPPING--
--------------------------------------------------------------------------------

--Necessary to avoid conflicts between Starbound's 'self' and Lua's 'self' tables
--TODO: Refactor 'self' to a better name, someday...
function setMoved(moved)
  self.moved = moved
end

--DEBUG---------------------------------------------
function debugPathEdgeColor(edge)
  local action = edge.action
  if action == "Walk" then
    return "blue"
  elseif action == "Jump" then
    return "green"
  elseif action == "Drop" then
    return "cyan"
  elseif action == "Swim" then
    return "white"
  elseif action == "Fly" then
    return "magenta"
  elseif action == "Land" then
    return "yellow"
  elseif action == "Arc" then
    if edge.target.velocity and edge.target.velocity[2] == 0 then
      return "yellow"
    end
    return "red"
  else
    return "red"
  end
end

function debugPath(pathfinder)
  if not self.debug then return end

  local position = mcontroller.position()
  local step = 0
  local prevStep = position
  while true do
    local edge = pathfinder:lookAhead(step)
    if edge then
      local nextStep = edge.target.position
      local color = debugPathEdgeColor(edge)
      world.debugLine(prevStep, nextStep, color)
      if edge.action == "Jump" then
        world.debugText(edge.jumpVelocity[2], {nextStep[1], nextStep[2]-1}, "red")
      end
      if edge.action == "Land" then
        local bounds = padBoundBox(-0.2, 0)
        bounds = {bounds[1] + nextStep[1],bounds[2] + nextStep[2],bounds[3] + nextStep[1],bounds[4] + nextStep[2]}
        util.debugRect(bounds, "yellow")
      end
      if edge.action == "Drop" then
        local bounds = padBoundBox(0.2, 0)
        bounds = {bounds[1] + prevStep[1],bounds[2] + prevStep[2],bounds[3] + prevStep[1],bounds[4] + prevStep[2]}
        util.debugRect(bounds, "yellow")
      end
      -- if edge.action == "Arc" then
      --   world.debugLine(nextStep, vec2.add(nextStep, edge.source.velocity or edge.target.velocity or {0,0}), "yellow")
      -- end
      world.debugPoint(nextStep, color)
      prevStep = nextStep
      step = step + 1
    else
      break
    end
  end
end
