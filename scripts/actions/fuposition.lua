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
