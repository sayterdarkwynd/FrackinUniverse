-- param position
-- param offset
-- output position
function offsetPosition(args, board)
  local position = args.position or mcontroller.position()
  local offset = (args.x and args.y) and {args.x, args.y} or args.offset

  if position == nil then return false end
  return true, {position = vec2.add(position, offset)}
end

-- param position
-- param multiplier
-- param direction
-- output position
function offsetDirection(args, board)
  if args.position == nil then return false end
  local offset = {args.direction * args.multiplier, 0}
  return true, {position = vec2.add(args.position, offset)}
end

-- param position
-- param minHeight
-- param maxHeight
-- param avoidLiquid
-- output position
function groundPosition(args, board)
  if args.position == nil then return false end

  local position = findGroundPosition(args.position, args.minHeight, args.maxHeight, args.avoidLiquid)
  if position == nil then return false end

  return true, {position = position}
end

-- param position
-- param minHeight
-- param maxHeight
-- param avoidLiquid
-- output position
function ceilingPosition(args, board)
  if args.position == nil then return false end

  local position = findCeilingPosition(args.position, args.minHeight, args.maxHeight, args.avoidLiquid)
  if position == nil then return false end

  return true, {position = position}
end

-- param position
function isInside(args, board)
  local material = world.material(args.position, "background")
  local hasMaterial = material ~= nil and material ~= false
  return hasMaterial and material ~= "dirt" and material ~= "drysand"
end

-- param from
-- param to
-- output vector
-- output x
-- output y
-- output magnitude
function distance(args, board)
  if args.from == nil or args.to == nil then return false end
  local distance = world.distance(args.to, args.from)
  return true, {vector = distance, x = distance[1], y = distance[2], magnitude = world.magnitude(args.to, args.from)}
end

-- param position
-- param target
-- param range
function inRange(args, board)
  if args.position == nil or args.target == nil or args.range == nil then return false end
  local distance = world.magnitude(args.target, args.position)
  return distance < args.range
end
