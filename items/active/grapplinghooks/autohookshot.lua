require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.fireOffset = config.getParameter("fireOffset")
  self.ropeOffset = config.getParameter("ropeOffset")
  self.ropeVisualOffset = config.getParameter("ropeVisualOffset")
  self.consumeOnUse = config.getParameter("consumeOnUse")
  self.projectileType = config.getParameter("projectileType")
  self.projectileParameters = config.getParameter("projectileParameters")
  self.reelInDistance = config.getParameter("reelInDistance")
  self.reelOutLength = config.getParameter("reelOutLength")
  self.breakLength = config.getParameter("breakLength")
  self.reelSpeed = config.getParameter("reelSpeed")
  self.controlForce = config.getParameter("controlForce")
  self.groundLagTime = config.getParameter("groundLagTime")

  self.rope = {}
  self.ropeLength = 0
  self.aimAngle = 0
  self.onGround = false
  self.onGroundTimer = 0
  self.facingDirection = 0
  self.projectileId = nil
  self.projectilePosition = nil
  self.anchored = false
  self.previousMoves = {}
  self.previousFireMode = nil

  --self.resetVelocity = false
end

function uninit()
  cancel()
end

function update(dt, fireMode, shiftHeld, moves)
  if fireMode == "primary" and self.previousFireMode ~= "primary" then
    if self.projectileId then
      cancel()
    elseif not status.statPositive("activeMovementAbilities") and not world.lineTileCollision(mcontroller.position(), firePosition()) then
      fire()
    end
  end
  self.previousFireMode = fireMode

  self.aimAngle, self.facingDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.facingDirection)

  trackGround(dt)
  trackProjectile()

  if self.projectileId then
    if world.entityExists(self.projectileId) then
      local position = mcontroller.position()
      local handPosition = vec2.add(position, activeItem.handPosition(self.ropeOffset))

      local newRope
      if #self.rope == 0 then
        newRope = {handPosition, self.projectilePosition}
      else
        newRope = copy(self.rope)
        table.insert(newRope, 1, world.nearestTo(newRope[1], handPosition))
        table.insert(newRope, world.nearestTo(newRope[#newRope], self.projectilePosition))
      end

      windRope(newRope)
      updateRope(newRope)
    else
      cancel()
    end
  end

  if self.ropeLength > self.breakLength then
    cancel()
  end

  if self.anchored then

    swing(moves)
  else
    activeItem.setArmAngle(self.aimAngle)
  end
end

function trackProjectile()
  if self.projectileId then
    if world.entityExists(self.projectileId) then
      local position = mcontroller.position()
      self.projectilePosition = vec2.add(world.distance(world.entityPosition(self.projectileId), position), position)
      if not self.anchored then
        self.anchored = world.callScriptedEntity(self.projectileId, "anchored")
      end
    else
      cancel()
    end
  end
end

function trackGround(dt)
  if mcontroller.onGround() then
    self.onGround = true
    self.onGroundTimer = self.groundLagTime
  else
    self.onGroundTimer = self.onGroundTimer - dt
    if self.onGroundTimer < 0 then
      self.onGround = false
    end
  end
end

function fire()
  cancel()

  local aimVector = vec2.rotate({1, 0}, self.aimAngle)
  aimVector[1] = aimVector[1] * self.facingDirection

  self.projectileId = world.spawnProjectile(
      self.projectileType,
      firePosition(),
      activeItem.ownerEntityId(),
      aimVector,
      false,
      self.projectileParameters
    )

  if self.projectileId then
    animator.playSound("fire")
    status.setPersistentEffects("grapplingHook", {{stat = "activeMovementAbilities", amount = 1}})
  end
end

function cancel()
  if self.projectileId and world.entityExists(self.projectileId) then
    world.callScriptedEntity(self.projectileId, "kill")
  end
  if self.projectileId and self.anchored and self.consumeOnUse then
    item.consume(1)
  end
  self.projectileId = nil
  self.projectilePosition = nil
  self.anchored = false
  updateRope({})
  status.clearPersistentEffects("grapplingHook")
end


function swing(moves)
  local canReel = self.ropeLength > self.reelInDistance or world.magnitude(self.rope[2], mcontroller.position()) > self.reelInDistance

  local armAngle = activeItem.aimAngle(self.fireOffset[2], self.rope[2])
  local pullDirection = vec2.withAngle(armAngle)
  --sb.logInfo("armang: %s, pullang: %s", armAngle,pullDirection)
  activeItem.setArmAngle(self.facingDirection == 1 and armAngle or math.pi - armAngle)

  -- if self.onGround then
  --     mcontroller.controlApproachVelocityAlongAngle(vec2.angle(pullDirection), self.reelSpeed, self.controlForce, true)
  -- else

    if moves.jump and not self.previousMoves.jump then
      if not mcontroller.canJump() then
        mcontroller.controlJump(true)
      end
      cancel()
    else
      if self.ropeLength < 3 then
        mcontroller.setVelocity({0,0})
      else
        mcontroller.setVelocity({self.reelSpeed * pullDirection[1], self.reelSpeed * pullDirection[2]})
      end
      --mcontroller.controlApproachVelocityAlongAngle(vec2.angle(pullDirection), self.reelSpeed, self.controlForce, true)
    end
  -- end

  self.previousMoves = moves
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function updateRope(newRope)
  local position = mcontroller.position()
  local previousRopeCount = #self.rope
  self.rope = newRope
  self.ropeLength = 0

  activeItem.setScriptedAnimationParameter("ropeOffset", self.ropeVisualOffset)
  for i = 2, #self.rope do
    self.ropeLength = self.ropeLength + vec2.mag(vec2.sub(self.rope[i], self.rope[i - 1]))
    activeItem.setScriptedAnimationParameter("p" .. i, self.rope[i])
  end
  for i = #self.rope + 1, previousRopeCount do
    activeItem.setScriptedAnimationParameter("p" .. i, nil)
  end
end

-- Pulls the given rope as tightly as possible around the idealized tile
-- geometry without changing the start or end points of the rope
function windRope(ropePoints)
  local sqrt2d2 = math.sqrt(2) / 2

  -- Returns whether the three given points are in a straight line (returns 0),
  -- go counter clocwise (returns > 0) or go clockwise (returns < 0)
  local function sign(p1, p2, p3)
    return (p1[1] - p3[1]) * (p2[2] - p3[2]) - (p2[1] - p3[1]) * (p1[2] - p3[2])
  end

  local i = 2
  while i < #ropePoints do
    local before = ropePoints[i - 1]
    local current = ropePoints[i]
    local after = ropePoints[i + 1]

    local curSign = sign(before, current, after)
    if curSign == 0 then
      table.remove(ropePoints, i)
    else
      local backDirection = vec2.norm(vec2.sub(before, current))
      local forwardDirection = vec2.norm(vec2.sub(after, current))
      local windDirection = vec2.norm(vec2.add(backDirection, forwardDirection))

      local keepCurrentPoint = false
      local crossedPoints = {}

      local function testCollisionPoint(point, inward)
        -- True if the given point is part of a block that this line is
        -- currently winding around
        local innerPoint = vec2.dot(windDirection, inward) > sqrt2d2

        if vec2.eq(before, point) or vec2.eq(after, point) then
          -- Don't need to collide with the previous and next points, they will
          -- not be removed and don't need to be added again
          return
        elseif vec2.eq(current, point) then
          -- If the current point is a previous collision with a block, keep it
          -- only if it is an inner point on the rope
          if innerPoint then
            keepCurrentPoint = true
          end
        else
          -- Otherwise, test for whether this point is in the triangle formed
          -- by the points before, current, after.  Test inclusively if this is
          -- an inner point, otherwise exclusively.

          local a, b, c
          if curSign < 0 then
            a, b, c = after, current, before
          else
            a, b, c = before, current, after
          end

          if innerPoint then
            if sign(point, a, b) >= 0 and sign(point, b, c) >= 0 and sign(point, c, a) >= 0 then
              table.insert(crossedPoints, point)
            end
          else
            if sign(point, a, b) > 0 and sign(point, b, c) > 0 and sign(point, c, a) > 0 then
              table.insert(crossedPoints, point)
            end
          end
        end
      end

      local xMin = math.ceil(math.min(before[1], current[1], after[1])) - 1
      local xMax = math.floor(math.max(before[1], current[1], after[1])) + 1
      local yMin = math.ceil(math.min(before[2], current[2], after[2])) - 1
      local yMax = math.floor(math.max(before[2], current[2], after[2])) + 1

      for x = xMin, xMax do
        for y = yMin, yMax do
          if world.pointTileCollision({x + 0.5, y + 0.5}, {"dynamic", "block"}) then
            testCollisionPoint({x, y}, {sqrt2d2, sqrt2d2})
            testCollisionPoint({x + 1, y}, {-sqrt2d2, sqrt2d2})
            testCollisionPoint({x + 1, y + 1}, {-sqrt2d2, -sqrt2d2})
            testCollisionPoint({x, y + 1}, {sqrt2d2, -sqrt2d2})
          end
          if keepCurrentPoint then break end
        end
        if keepCurrentPoint then break end
      end

      if keepCurrentPoint then
        -- If we have found that the current point is still an inner tile
        -- collision point, keep it and move on.
        i = i + 1
      elseif #crossedPoints == 0 then
        -- Otherwise, if there are no colliding points, then we can tighten the
        -- rope by eliminating it entirely.
        table.remove(ropePoints, i)
      else
        -- If the point is no longer an inner tile collision point but there
        -- ARE colliding points, add the point that is encountered soonest when
        -- winding the rope around.  We still keep the current point in the
        -- list when adding a new rope point, which generally makes an odd
        -- empty space shape, but this is intentional as we will visit the
        -- current point a second time on the next time through the loop, and
        -- hopefully eliminate the space or possibly cause a second rope
        -- collision.

        -- Sort the crossed points by the lowest rotation angle from the before
        -- -> current vector to the new before -> crossed vector, so as not to
        -- skip any crossed points when adding a new vertex.  If several points
        -- are along the same angle, then sort with the furthest away one
        -- first.  This is common on straight edges of geometry, and prevents
        -- tons of repeat vertexes for a single frame
        table.sort(crossedPoints, function(a, b)
          local aBack = vec2.sub(before, a)
          local bBack = vec2.sub(before, b)
          local lenABack = vec2.mag(aBack)
          local lenBBack = vec2.mag(bBack)
          local dotABack = vec2.dot(vec2.div(aBack, lenABack), backDirection)
          local dotBBack = vec2.dot(vec2.div(bBack, lenBBack), backDirection)
          if dotABack == dotBBack then
            return lenABack > lenBBack
          else
            return dotABack > dotBBack
          end
        end)

        table.insert(ropePoints, i, crossedPoints[1])
        i = i + 1
      end
    end
  end
end
