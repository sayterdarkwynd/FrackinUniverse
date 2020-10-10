function hashHouseObject(object)
  -- The hash of a scanned object depends on what the object is, and its
  -- position in the house relative to the deed
  local distance = world.distance(self.position, world.entityPosition(object))
  return util.hashString(world.entityName(object) .. vecToString(distance))
end

function hashPolygon(polygon)
  local hash = 0
  for _,vertex in ipairs(polygon) do
    -- Combine hashes with just xor so that it doesn't depend on the order of vertices
    local distance = world.distance(self.position, vertex)
    hash = hash ~ util.hashString(vecToString(distance))
  end
  return hash
end

function scanHouseContents(boundary)
  local objects = world.objectQuery(self.position, self.position, {poly = boundary, boundMode = "Position"})
  local objectSet = {}
  local hash = hashPolygon(boundary)
  local otherDeed = false

  for _,object in ipairs(objects) do
    -- Don't include the deed itself in the scan since it is not there during
    -- init(), which will cause the hash to be different on subsequent scans.
    if object ~= entity.id() then
      -- Simple xor of object hashes so that the result doesn't depend on the
      -- order objects are scanned in.
      hash = hash ~ hashHouseObject(object)

      if world.entityName(object) == "colonydeed" then
        otherDeed = true
      else
        objectSet[object] = true
      end
    end
  end

  util.debugLog("House hash: " .. hash)

  return {
      hash = hash,
      otherDeed = otherDeed,
      objects = objectSet
    }
end

function findHouseBoundary(position, remainingPerimeter)
  local floor, poly = nil, nil
  floor, remainingPerimeter = findFloor(position, remainingPerimeter)
  if not floor then
    return {
      floor = nil,
      poly = nil,
      doors = {}
    }
  end

  local scanResults = scanHouseBoundary(floor, remainingPerimeter)
  poly, remainingPerimeter, doors = scanResults.poly, scanResults.remainingPerimeter, scanResults.doors
  if not poly then
    return {
      floor = floor,
      poly = nil,
      doors = doors
    }
  end

  if not world.polyContains(poly, self.position) then
    -- If the poly does not contain the deed's position, the poly could be
    -- of an internal ledge, distconnected from the exterior walls. Try
    -- finding floor below the current poly/ledge and re-scanning the boundary
    -- from there.
    return findHouseBoundary(vecAdd(polyLowest(poly), {0, -1}), remainingPerimeter)
  end

  if self.requireFilledBackground and not isBackgroundFilled(poly) then
    return {
      floor = floor,
      poly = nil,
      doors = doors
    }
  end

  return {
    floor = floor,
    poly = poly,
    doors = doors
  }
end

function countObjectTags(objectId)
  local tags = {}
  local objectTags = world.getObjectParameter(objectId, "colonyTags", {})
  local spaces = #(world.objectSpaces(objectId))
  for _,tag in ipairs(objectTags) do
    tags[tag] = (tags[tag] or 0) + spaces
  end
  return tags
end

function countTags(...)
  local tags = {}
  if isShipWorld() then
    tags["ship"] = 1
  end

  for _,objectSet in ipairs({...}) do
    for objectId,_ in pairs(objectSet) do
      local objectTags = countObjectTags(objectId)
      for tag,count in pairs(objectTags) do
        tags[tag] = (tags[tag] or 0) + count
      end
    end
  end

  util.debugLog("Tag count:")
  local anyTags = false
  for tag,count in pairs(tags) do
    util.debugLog("  " .. tag .. " = " .. count)
    anyTags = true
  end
  if not anyTags then
    util.debugLog("  No tags.")
  end

  return tags
end

function countObjects(...)
  local objectCounts = {}
  util.debugLog("House at " .. vecToString(self.position) .. " contains:")
  for _,objectSet in ipairs({...}) do
    for objectId,_ in pairs(objectSet) do
      local objectName = world.entityName(objectId)
      objectCounts[objectName] = (objectCounts[objectName] or 0) + 1
      util.debugLog("  " .. world.entityName(objectId))
    end
  end
  return objectCounts
end

function isShipWorld()
  return world.getProperty("ship.fuel") ~= nil
end

function polyLowest(poly)
  local lowest = poly[1]
  for _,point in ipairs(poly) do
    if point[2] < lowest[2] then
      lowest = point
    end
  end
  return lowest
end

function vecAdd(v, u)
  return {v[1] + u[1], v[2] + u[2]}
end

function vecEquals(v, u)
  return v[1] == u[1] and v[2] == u[2]
end

function vecToString(v)
  return "{" .. table.concat(v, ", ") .. "}"
end

function findFloor(position, remainingPerimeter)
  -- Find the center of the nearest floor tile below position
  position = {
      util.round(position[1]-0.5)+0.5,
      util.round(position[2]-0.5)+0.5
    }
  while not isHouseBoundaryTile(position) do
    position = vecAdd(position, {0, -1})
    remainingPerimeter = remainingPerimeter - 1
    if remainingPerimeter < 0 then
      util.debugLog("findFloor ran out of perimeter")
      return nil
    end
  end
  return position, remainingPerimeter
end

function wrap(value, max)
  -- Lua's % is a remainder operator, not modulo.
  -- We add max to value before %'ing it to carefully handle small negative
  -- values > -max.
  return ((value + max - 1) % max) + 1
end

function polyBoundBox(poly)
  local minX = poly[1][1]
  local maxX = poly[1][1]
  local minY = poly[1][2]
  local maxY = poly[1][2]
  for _,vertex in ipairs(poly) do
    if vertex[1] < minX then
      minX = vertex[1]
    end
    if vertex[1] > maxX then
      maxX = vertex[1]
    end
    if vertex[2] < minY then
      minY = vertex[2]
    end
    if vertex[2] > maxY then
      maxY = vertex[2]
    end
  end
  return {minX,minY, maxX,maxY}
end

function isBackgroundFilled(poly)
  if isShipWorld() then
    -- Consider the background filled if we're on a ship. Otherwise it would
    -- be weird when the house is rejected because there's a window in it.
    return true
  end
  local boundBox = polyBoundBox(poly)
  for x = math.ceil(boundBox[1]), math.floor(boundBox[3]) do
    for y = math.ceil(boundBox[2]), math.floor(boundBox[4]) do
      local pos = {x,y}
      if world.polyContains(poly, pos) then
        -- permit gaps in the background where the foreground is filled
        if not world.tileIsOccupied(pos, false) and not world.tileIsOccupied(pos, true) then
          return false
        end
      end
    end
  end
  return true
end

scanDirections = {
    {1, 0}, {1, 1},
    {0, 1}, {-1, 1},
    {-1, 0}, {-1, -1},
    {0, -1}, {1, -1}
  }

nextDirections = {2, 1, 0, -1, -2, 4}

function dirDiff(d1, d2)
  -- Return the difference of d1 and d2, taking into account the wrapping from
  -- the end of scanDirections to the beginning.
  local diff = math.abs(d1 - d2) % #scanDirections
  return math.min(diff, #scanDirections - diff)
end

function scanHouseBoundary(start, remainingPerimeter)
  -- Scan the boundaries of the house from start, going anti-clockwise around
  -- the floor, walls and ceiling.
  local startDir = 1
  local dir = startDir
  local poly = {start}
  local doors = {}
  local position = vecAdd(start, scanDirections[dir])

  while remainingPerimeter >= 0 do
    local doorsHere = doorsAtPosition(position)
    for _,doorId in pairs(doorsHere) do
      doors[doorId] = true
    end

    local connected = false
    for i,dirOffset in ipairs(nextDirections) do
      local nextDir = wrap(dir+dirOffset, #scanDirections)
      local nextPosition = vecAdd(position, scanDirections[nextDir])

      if isHouseBoundaryTile(nextPosition) then
        if dir ~= nextDir then
          poly[#poly+1] = nextPosition
        else
          poly[#poly] = nextPosition
        end
        dir = nextDir
        position = nextPosition
        connected = true
        break
      end
    end
    if not connected then
      return {
          remainingPerimeter = remainingPerimeter,
          doors = doors
        }
    end

    if vecEquals(position, start) and dirDiff(dir, startDir) <= 1 then
      return {
          poly = poly,
          remainingPerimeter = remainingPerimeter,
          doors = doors
        }
    end

    remainingPerimeter = remainingPerimeter - 1
  end
  util.debugLog("scanHouseBoundary ran out of perimeter")
  util.debugPoly(poly, "red")
  return {
      remainingPerimeter = remainingPerimeter,
      doors = doors
    }
end

function isHouseBoundaryTile(position)
  return world.pointTileCollision(position) or isDoor(position)
end

function isDoor(position)
  return #doorsAtPosition(position) > 0
end

function doorsAtPosition(position)
  return world.objectQuery(position, position, {callScript = "doorOccupiesSpace", callScriptArgs = {world.xwrap(position)}})
end
