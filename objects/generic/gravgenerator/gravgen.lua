require "/scripts/vec2.lua"
require "/objects/playerstation/stationgrid.lua"

function init()
  object.setUniqueId(config.getParameter("uniqueId"))

 --[[ self.partConfig = root.assetJson("/dungeons/space/playerstation/parts.config")

  if not storage.grid then
    local grid = jobject()
    grid.tiles = jobject()
    grid.tileSize = self.partConfig.partSize
    grid.tileBorder = self.partConfig.partBorder

    local offset = config.getParameter("partOriginOffset")
    local startPos = world.distance(vec2.sub(entity.position(), offset), {0, 0})
    grid.worldOffset = {
      startPos[1] % (grid.tileSize[1] + grid.tileBorder[1]),
      startPos[2] % (grid.tileSize[2] + grid.tileBorder[2])
    }
    -- add a 1 tile offset from the bottom
    grid.worldOffset[2] = grid.worldOffset[2] + (grid.tileSize[2] + grid.tileBorder[2])

    grid.size = vec2.floor({
      world.size()[1] / (grid.tileSize[1] + grid.tileBorder[1]),
      (world.size()[2] - grid.worldOffset[2]) / (grid.tileSize[2] + grid.tileBorder[2])
    })
    -- remove 1 tile from the top and 1 from the bottom
    grid.size[2] = grid.size[2] - 2

    local startTile = worldToTile(grid, startPos)
    for _,tile in pairs(self.partConfig.parts.start.tiles) do
      claimTile(grid, vec2.add(tile, startTile), partTileAnchors(self.partConfig.parts.start, tile))
    end

    storage.grid = grid
  end

  message.setHandler("grid", function() return storage.grid end)

  storage.hideExpansionSlots = storage.hideExpansionSlots or false
  message.setHandler("hideExpansionSlots", function() return storage.hideExpansionSlots end)
  message.setHandler("setHideExpansionSlots", function(_, _, hide)
      storage.hideExpansionSlots = hide
    end)]]--

  message.setHandler("setGravity", function(_, _, gravity)
      setGravity(gravity)
    end)
  CurrentGravity=world.gravity(object.position())
  setGravity(storage.gravity or  CurrentGravity)

  --[[world.setDungeonBreathable(65532, true)
  world.setDungeonBreathable(65531, true)]]--

  --[[self.tileLocks = {}
  message.setHandler("lockPartPlacement", function(_,_, sourceEntity, part, tilePos)
    for _,t in pairs(partTiles(part, tilePos)) do
      local lock = tileLock(t)
      if lock and lock.source ~= sourceEntity then
        return false
      end
    end
    for _,t in pairs(partTiles(part, tilePos)) do
      table.insert(self.tileLocks, {source = sourceEntity, tile = t, timer = 2.0})
    end
    return true
  end)

  message.setHandler("confirmPartPlacement", function(_,_, sourceEntity, part, tilePos)
    for _,t in pairs(partTiles(part, tilePos)) do
      local lock = tileLock(t)
      if not lock or lock.source ~= sourceEntity then
        return false
      end
    end
    placePart(part, tilePos)
    return true
  end)]]--
end

function onInteraction()
  local interactData = root.assetJson(config.getParameter("interactData"))
  interactData.gravity = storage.gravity
  --interactData.hideExpansionSlots = storage.hideExpansionSlots
  return {config.getParameter("interactAction"), interactData}
end

function update(dt)
  --[[for _,l in pairs(self.tileLocks) do
    l.timer = l.timer - dt
  end
  self.tileLocks = util.filter(self.tileLocks, function(lock) return lock.timer > 0 end)]]--
end

--[[function dungeonPlacementWorldPos(part, tilePos)
  tilePos = vec2.add(tilePos, {0, partSize(part)[2]})
  local worldPos = tileWorldPos(storage.grid, tilePos)
  return vec2.add(worldPos, {-storage.grid.tileBorder[1], 0})
end

function tileLock(tile)
  for _,lock in pairs(self.tileLocks) do
    if compare(lock.tile, tile) then
      return lock
    end
  end
end

function placePart(part, tilePos)
  if partAllowedAt(storage.grid, part, tilePos) then
    world.placeDungeon(part.dungeon, dungeonPlacementWorldPos(part, tilePos), 0)
    for _,t in pairs(part.tiles) do
      claimTile(storage.grid, vec2.add(t, tilePos), partTileAnchors(part, t))
    end
    return true
  end
  return false
end
]]--
function setGravity(gravity)
  storage.gravity = gravity
  world.setDungeonGravity(0, gravity)
  world.setDungeonGravity(65533, gravity)
  world.setDungeonGravity(65532, gravity)
  world.setDungeonGravity(65531, gravity)
  world.setDungeonGravity(65535, gravity)
end
