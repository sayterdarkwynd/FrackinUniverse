require "/scripts/rect.lua"
require "/scripts/poly.lua"

-- param position
-- param offset
-- param x
-- param y
-- param collisionType
function lineTileCollision(args, board)
  local sensorOffset = (args.x and args.y) and {args.x, args.y} or args.offset
  if sensorOffset == nil or args.position == nil then return false end
  local targetPosition = vec2.add(args.position, sensorOffset)
  return world.lineTileCollision(args.position, targetPosition, args.collisionType)
end

function visibleToPlayer(args, board)
  local bounds = mcontroller.boundBox()
  local position = mcontroller.position()
  local collisionArea = {bounds[1] + position[1], bounds[2] + position[2], bounds[3] + position[1], bounds[4] + position[2]}

  return world.isVisibleToPlayer(collisionArea)
end

-- param direction
function wallCollision(args, board)
  if not args.direction then return false end

  local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())
  if args.direction > 0 then
    bounds[1] = bounds[3] - 0.2
    bounds[3] = bounds[3] + 0.2
  else
    bounds[3] = bounds[1] + 0.2
    bounds[1] = bounds[1] - 0.2
  end
  bounds[2] = bounds[2] + 1.0

  return world.rectTileCollision(bounds, {"Null","Block","Dynamic"})
end


function groundCollision(args, board)
  local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())
  local groundRect = {bounds[1], bounds[2] - 0.25, bounds[3], bounds[2]}

  return world.rectTileCollision(groundRect, {"Null","Block","Dynamic","Platform"})
end

-- param dirVector
function boundsCollision(args, board)
  local bounds = rect.translate(mcontroller.boundBox(), mcontroller.position())

  if args.dirVector == nil then
    bounds = rect.pad(bounds, 0.25)
  elseif args.dirVector[1] > 0 then
    bounds[1] = bounds[3]
    bounds[3] = bounds[3] + 0.25
  elseif args.dirVector[1] < 0 then
    bounds[3] = bounds[1]
    bounds[1] = bounds[1] - 0.25
  elseif args.dirVector[2] > 0 then
    bounds[2] = bounds[4]
    bounds[4] = bounds[4] + 0.25
  else
    bounds[4] = bounds[2]
    bounds[2] = bounds[2] - 0.25
  end
  util.debugRect(bounds, "yellow")

  return world.rectTileCollision(bounds, {"Null","Block","Dynamic"})
end

-- param position
function pointTileCollision(args, output)
  if args.position == nil then return false end

  return world.pointTileCollision(args.position, {"Null","Block","Dynamic"})
end

-- param startLine
-- param endLine
-- param excludeLiquidIds
function lineLiquidCollision(args, board)
  local blocks = world.liquidAlongLine(args.startLine, args.endLine)
  if args.excludeLiquidIds then
    blocks = util.filter(blocks, function(liquid) return not contains(args.excludeLiquidIds, liquid[2][1]) end)
  end
  return #blocks > 0
end

-- param startLine
-- param endLine
-- param collisionType
-- output blocks
function lineBlockCollision(args, board)
  if arg.startline == nil or args.offset== nil then return false end
  local blocks = world.collisionBlocksAlongLine(args.startLine, args.endLine, args.collisionType)
  return #blocks > 0, {blocks = blocks}
end

-- param rectangle
-- param collisionType
function rectTileCollision(args, board)
  if arg.rect == nil then return false end
  return world.rectTileCollision(args.rect, args.collisionType)
end

--param bounds
--param offset
--outpud bounds
function boundsTranslate(args, board)
  if arg.bounds == nil or args.offset==nil then return false end
  local bounds
  if #args.bounds == 4 then bounds = rect.translate(args.bounds, args.offset)
  else bounds = poly.translate(args.bounds, args.offset) end
  return true, {bounds = bounds}
end
