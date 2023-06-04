require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/util.lua"

local originalUpdate = update
local originalInit = init

function init()
	originalInit()
	message.setHandler("pandorasboxGetHarvestTimeLeft", function ()
		if storage.lastHarvest then
			return math.max(storage.harvestTime - (world.time() - storage.lastHarvest), 0)
		end
	end)
end

function resetMonsterHarvest()
  storage.lastHarvest = world.time()
  harvestTimeLeft = config.getParameter("pandorasboxHarvestTimeLeft")
  if not storage.harvestTime and harvestTimeLeft then
    storage.harvestTime = harvestTimeLeft
  else
    storage.harvestTime = util.randomInRange(config.getParameter("harvestTime"))
  end
end

function hasMonsterHarvest(args, board)
  if not storage.lastHarvest then
    resetMonsterHarvest()
  end

  if world.time() - storage.lastHarvest >= storage.harvestTime then
    return true
  else
    return false
  end
end

function update(dt)
    originalUpdate(dt)
    if config.getParameter("wildHarvestable") or config.getParameter("ownerUuid") then
        monster.setInteractive(hasMonsterHarvest())
    end
end

function dropMonsterHarvest(args, board)
  local treasurePool = config.getParameter("harvestPool")
  local treasure = root.createTreasure(treasurePool, monster.level())
  local spawnPosition = vec2.add(mcontroller.position(), config.getParameter("harvestSpawnOffset", {0, 0}))

  for _,item in pairs(treasure) do
    world.spawnItem(item, spawnPosition)
  end
  resetMonsterHarvest()
  return true
end

function interact()
if hasMonsterHarvest() then
dropMonsterHarvest()
  end
end
