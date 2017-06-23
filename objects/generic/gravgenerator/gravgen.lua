require "/scripts/vec2.lua"
require "/objects/playerstation/stationgrid.lua"

function init()
  object.setUniqueId(config.getParameter("uniqueId"))


    local grid = jobject()
    grid.tiles = jobject()
    grid.tileSize = 5
    grid.tileBorder = 5

    local offset = config.getParameter("partOriginOffset")
    local startPos = world.distance(vec2.sub(entity.position(), offset), {0, 0})
    grid.worldOffset = {
      startPos[1] % (grid.tileSize[1] + grid.tileBorder[1]),
      startPos[2] % (grid.tileSize[2] + grid.tileBorder[2])
    }
    -- add a 1 tile offset from the bottom
    grid.worldOffset[2] = grid.worldOffset[2] + (grid.tileSize[2] + grid.tileBorder[2])

    grid.size = vec2.floor({
      10 / (grid.tileSize[1] + grid.tileBorder[1]),
      (10 - grid.worldOffset[2]) / (grid.tileSize[2] + grid.tileBorder[2])
    })
    -- remove 1 tile from the top and 1 from the bottom
    grid.size[2] = grid.size[2] - 2

    local startTile = worldToTile(grid, startPos)
    for _,tile in pairs(self.partConfig.parts.start.tiles) do
      claimTile(grid, vec2.add(tile, startTile), partTileAnchors(self.partConfig.parts.start, tile))
    end

    storage.grid = grid


  message.setHandler("setGravity", function(_, _, gravity)
      setGravity(gravity)
    end)
  CurrentGravity=world.gravity(object.position())
  setGravity(storage.gravity or  CurrentGravity)
end

function onInteraction()
  local interactData = root.assetJson(config.getParameter("interactData"))
  interactData.gravity = storage.gravity
  return {config.getParameter("interactAction"), interactData}
end

function update(dt)

end

function setGravity(gravity)
  storage.gravity = gravity
  world.setDungeonGravity(0, gravity)
  world.setDungeonGravity(65533, gravity)
  world.setDungeonGravity(65532, gravity)
  world.setDungeonGravity(65531, gravity)
  world.setDungeonGravity(65535, gravity)
end
