-- also checks microdungeons!
function dungeonId(args, board)
  if args.position == nil then return false end

  local id = world.dungeonId(args.position)
  if id ~= 0 then return true, {dungeonId = id}
  else return false, {dungeonId = 0} end
end
