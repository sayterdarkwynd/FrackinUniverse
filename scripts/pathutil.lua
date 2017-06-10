require "/scripts/rect.lua"

--The time it would take to fall distance
function timeToFall(distance)
  local gravity = world.gravity(mcontroller.position())
  return math.sqrt(2 * distance / gravity)
end

--Checks if the entity can stand in this position
function validStandingPosition(position, avoidLiquid, collisionSet, bounds)
  collisionSet = collisionSet or {"Null", "Block"}
  bounds = bounds or mcontroller.boundBox()

  local boundRegion = rect.translate(bounds, position)
  local groundRegion = {
    position[1] + bounds[1], position[2] + bounds[2] - 1,
    position[1] + bounds[3], position[2] + bounds[2]
  }
  if (world.rectTileCollision(groundRegion, {"Null", "Block", "Dynamic", "Platform"}) or (not avoidLiquid and world.liquidAt(position)))
     and not world.rectTileCollision(boundRegion, collisionSet)  then
    return true
  end
  return false
end

--Find a valid ground position
function findGroundPosition(position, minHeight, maxHeight, avoidLiquid, collisionSet, bounds)
  bounds = bounds or mcontroller.boundBox()

  -- Align the vertical position of the bottom of our feet with the top
  -- of the row of tiles below:
  position = {position[1], math.ceil(position[2]) - (bounds[2] % 1)}

  local groundPosition
  for y = 0, math.max(math.abs(minHeight), math.abs(maxHeight)) do
    -- -- Look up
    if y <= maxHeight and validStandingPosition({position[1], position[2] + y}, avoidLiquid, collisionSet, bounds) then
      groundPosition = {position[1], position[2] + y}
      break
    end
    -- Look down
    if -y >= minHeight and validStandingPosition({position[1], position[2] - y}, avoidLiquid, collisionSet, bounds) then
      groundPosition = {position[1], position[2] - y}
      break
    end
  end

  if groundPosition and avoidLiquid then
    local liquidLevel = world.liquidAt(rect.translate(bounds, groundPosition))
    if liquidLevel and liquidLevel[2] >= 0.1 then
      return nil
    end
  end

  return groundPosition
end

--Checks if the entity can stand in this position
function validCeilingPosition(position, avoidLiquid, collisionSet, bounds)
  collisionSet = collisionSet or {"Null", "Block"}
  bounds = bounds or mcontroller.boundBox()

  local boundRegion = rect.translate(bounds, position)
  local groundRegion = {
    position[1] + bounds[1], position[3] + bounds[2] + 1,
    position[1] + bounds[3], position[3] + bounds[2]
  }
  if (world.rectTileCollision(groundRegion, {"Null", "Block", "Dynamic", "slippery"}) or (not avoidLiquid and world.liquidAt(position)))
     and not world.rectTileCollision(boundRegion, collisionSet)  then
    return true
  end
  return false
end

--Find a valid ground position
function findCeilingPosition(position, minHeight, maxHeight, avoidLiquid, collisionSet, bounds)
  bounds = bounds or mcontroller.boundBox()
  rect.rotate(bounds,math.pi)

  -- Align the vertical position of the bottom of our feet with the top
  -- of the row of tiles below:
  position = {position[1], math.ceil(position[2]) - (bounds[4] % 1)}

  local ceilingPosition
  for y = 0, math.max(math.abs(minHeight), math.abs(maxHeight)) do
    -- -- Look up
    if y <= maxHeight and validCeilingPosition({position[1], position[2] + y}, avoidLiquid, collisionSet, bounds) then
      groundPosition = {position[1], position[2] + y}
      break
    end
    -- Look down
    if -y >= minHeight and validCeilingPosition({position[1], position[2] - y}, avoidLiquid, collisionSet, bounds) then
      groundPosition = {position[1], position[2] - y}
      break
    end
  end

  if groundPosition and avoidLiquid then
    local liquidLevel = world.liquidAt(rect.translate(bounds, groundPosition))
    if liquidLevel and liquidLevel[2] >= 0.1 then
      return nil
    end
  end

  return groundPosition
end

--Check if entity is on solid ground (not platforms)
function onSolidGround()
  local position = mcontroller.position()
  local bounds = mcontroller.boundBox()

  local groundRegion = {
    position[1] + bounds[1], position[2] + bounds[2] - 1,
    position[1] + bounds[3], position[2] + bounds[2]
  }
  return world.rectTileCollision(groundRegion, {"Null", "Block", "Dynamic", "Slippery"})
end

function padBoundBox(xPadding, yPadding)
  local bounds = mcontroller.boundBox()
  bounds[1] = bounds[1] - xPadding
  bounds[3] = bounds[3] + xPadding
  bounds[2] = bounds[2] - yPadding
  bounds[4] = bounds[4] + yPadding
  return bounds
end

function openDoorsAhead()
  local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())
  bounds[2] = bounds[2] + 0.5
  bounds[4] = bounds[4] - 0.5
  if mcontroller.facingDirection() > 0 then
    bounds[1] = bounds[3]
    bounds[3] = bounds[3] + 1
  else
    bounds[3] = bounds[1]
    bounds[1] = bounds[1] - 1
  end
  if world.rectTileCollision(bounds, {"Dynamic"}) then
    -- There is a colliding object in the way. See if we can open it
    local closedDoorIds = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "closedDoor" } })
    if #closedDoorIds == 0 then
      return
    else
      for _, closedDoorId in pairs(closedDoorIds) do
        world.sendEntityMessage(closedDoorId, "openDoor")
      end
    end
  end
end

function closeDoorsBehind()
  local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())
  bounds[2] = bounds[2] + 0.5
  bounds[4] = bounds[4] - 0.5
  if mcontroller.facingDirection() > 0 then
    bounds[3] = bounds[1] - 1
    bounds[1] = bounds[1] - 2
  else
    bounds[1] = bounds[3] + 1
    bounds[3] = bounds[3] + 2
  end
  if not world.rectTileCollision(bounds, {"Dynamic"}) then
    local openDoorIds = world.entityQuery(rect.ll(bounds), rect.ur(bounds), { includedTypes = {"object"}, callScript = "hasCapability", callScriptArgs = { "openDoor" } })
    if #openDoorIds == 0 then
      return
    else
      for _, openDoorId in pairs(openDoorIds) do
        local doorBounds = objectBounds(openDoorId)
        local npcs = world.entityQuery(rect.ll(doorBounds), rect.ur(doorBounds), {includedTypes = {"npc"}})
        if #npcs == 0 then
          world.sendEntityMessage(openDoorId, "closeDoor")
        end
      end
    end
  end
end

function objectBounds(objectId)
  local bounds = {9999, 9999, 0, 0}
  local spaces = world.objectSpaces(objectId)
  for _,space in pairs(spaces) do
    bounds = {
      math.min(space[1], bounds[1]),
      math.min(space[2], bounds[2]),
      math.max(space[1] + 1, bounds[3]),
      math.max(space[2] + 1, bounds[4])
    }
  end
  return rect.translate(bounds, world.entityPosition(objectId))
end
