function init()
	script.setUpdateDelta(config.getParameter("refresh"))
	item = config.getParameter("item")
	count = world.entityHasCountOfItem(entity.id(), item)
	maxAmount = config.getParameter("maxAmount")
	configAmount = config.getParameter("amount")
	maxDrop = math.min(configAmount, 1000)
end

function update(dt)
	if world.entityType(entity.id())=="player" and not status.statusProperty("fu_afk_120s") then
		for _, entityID in pairs (world.itemDropQuery(entity.position(), 5)) do
			if world.entityName(entityID) == item then
				return
			end
		end
		if count and count < maxAmount then
			world.spawnItem(item, entity.position(), math.min(configAmount, maxAmount - count), {price = 0})
		end
	end
end