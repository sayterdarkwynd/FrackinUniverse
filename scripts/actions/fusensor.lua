require "/scripts/rect.lua"
require "/scripts/poly.lua"

-- param startLine
-- param endLine
-- param collisionType
-- output blocks
function lineBlockCollision(args, board)
  if args.startLine == nil or args.endLine == nil then return false end
  local blocks = world.collisionBlocksAlongLine(args.startLine, args.endLine, args.collisionType)
  return true, {blocks = blocks}
end

-- param rectangle
-- param collisionType
function rectTileCollision(args, board)
  if args.rect == nil then return false end
  return world.rectTileCollision(args.rect, args.collisionType)
end

--param bounds
--param offset
--outpud bounds
function boundsTranslate(args, board)
  if args.bounds == nil or args.offset==nil then return false end
  local bounds
  if #args.bounds == 4 then bounds = rect.translate(args.bounds, args.offset)
  else bounds = poly.translate(args.bounds, args.offset) end
  return true, {bounds = bounds}
end
