require "/scripts/util.lua"

function init()
  self.value = config.getParameter("refresh")
  script.setUpdateDelta(self.value)
end

function update(dt)
	item = config.getParameter("item")
	count = world.entityHasCountOfItem(entity.id(), item)
	maxAmount = config.getParameter("maxAmount")
	configAmount = config.getParameter("amount")
	canSpawn = true
	if configAmount > 1000 then
		maxDrop = 1000
	else
		maxDrop = configAmount
	end
	for _, entityID in pairs (world.itemDropQuery(entity.position(), 5)) do
		isItem = util.tableToString(world.itemDropItem(entityID))
		if isItem == "{ name = " .. item .. ", parameters = { price = 0 }, count = " .. maxDrop .." }" then
			canSpawn = false
			break
		end
	end
	if count and count < maxAmount and canSpawn == true then
		if count + configAmount > maxAmount then
			amount = maxAmount - count
		else
			amount = configAmount
		end
		world.spawnItem(item, entity.position(), amount, {price = 0})
	end
end

function uninit()
  
end