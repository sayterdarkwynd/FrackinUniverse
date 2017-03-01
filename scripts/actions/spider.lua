-- param position
function backwallCollision(args, output)
  args = parseArgs(args, {
    position = "self"
  })
  local position = BData:getPosition(args.position)
  local material = world.material(position, "background")
  if position == nil or material == nil or material == false then return false end
  return true
end

-- param position
-- param material
function materialCollision(args, output)
  args = parseArgs(args, {
    position = "self",
    material = "spidersilkblock"
  })
  local position = BData:getPosition(args.position)
  local material = world.material(position, "background")
  if position == nil or material == nil or material == false then return false end
  if material == nil return true end
  return material == "material"
end
