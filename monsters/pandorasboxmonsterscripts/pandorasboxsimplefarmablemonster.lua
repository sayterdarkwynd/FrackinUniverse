require "/scripts/vec2.lua"
require "/scripts/poly.lua"
require "/scripts/util.lua"

local originalUpdate = update
local originalInit = init
local cacheHarvestTime

function init()
	originalInit()
	message.setHandler("pandorasboxGetHarvestTimeLeft", function ()
		if storage.lastHarvest then
			return math.max(storage.harvestTime - (world.time() - storage.lastHarvest), 0)
		end
	end)
	cacheHarvestTime=config.getParameter("harvestTime")
end

function resetMonsterHarvest()
	cacheHarvestTime=config.getParameter("harvestTime")
	storage.lastHarvest = world.time()
	harvestTimeLeft = config.getParameter("pandorasboxHarvestTimeLeft")
	if not storage.harvestTime and harvestTimeLeft then
		storage.harvestTime = harvestTimeLeft
	else
		storage.harvestTime = util.randomInRange(cacheHarvestTime)
	end
end

function resolveStageDuration(dur)
	if type(dur)=="table" then
		return math.max(unpack(dur))
	else
		return dur
	end
end

function hasMonsterHarvest(args, board)
	local harvestMath=(world.time() - storage.lastHarvest)
	if (not storage.lastHarvest) or ((not cacheHarvestTime) or (harvestMath<0) or (harvestMath>=(resolveStageDuration(cacheHarvestTime))*100)) then
		resetMonsterHarvest()
		return false
	end

	if harvestMath >= storage.harvestTime then
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
