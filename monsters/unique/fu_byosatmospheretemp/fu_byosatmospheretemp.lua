require "/objects/spawner/colonydeed/scanning.lua"
require "/scripts/util.lua"

function init()
	message.setHandler("fu_checkByosAtmosphere", function(_, _, playerSelf)
		self = playerSelf
		room = findHouseBoundary(self.position, self.maxPerimeter)
		status.setResource("health", -1)
		if not room.poly then
			return false
		else
			return true
		end
	end)
	monster.setUniqueId(config.getParameter("uniqueId"))
	timer = 5
end

function update(dt)
	if timer <= 0 then
		status.setResource("health", -1)
	else
		timer = timer - dt
	end
end

function isBackgroundFilled(poly)
  local boundBox = polyBoundBox(poly)
  world.loadRegion(boundBox)
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

function isHouseBoundaryTile(position)
  world.loadRegion(polyBoundBox({position}))
  return world.pointTileCollision(position)
end