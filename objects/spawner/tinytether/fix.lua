require "/scripts/util.lua"
require "/scripts/pathutil.lua"


-- Finds a position to spawn a (potentially large) entity near the given
-- position that doesn't collide with the terrain.
function findBestPosition(nearPosition, collisionPoly)
  if not world.polyCollision(collisionPoly, nearPosition, {"Null", "Block"}) then
    return nearPosition
  end

  local bounds = util.boundBox(collisionPoly)
  local height = bounds[4] - bounds[2]
  local collisionSet = {"Null", "Block", "Platform"}
  local position = findGroundPosition(nearPosition, -height, height, false, collisionSet, bounds)
  if position then
    position = vec2.add(position, {0, height / 2.0})
  end
  return position or nearPosition
end
