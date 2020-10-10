function init()
	baseRefresh=config.getParameter("refresh")
	script.setUpdateDelta(baseRefresh*(1+afkLevel()))
	item = config.getParameter("item")
	count = world.entityHasCountOfItem(entity.id(), item)
	maxAmount = config.getParameter("maxAmount")
	configAmount = config.getParameter("amount")
	maxDrop = math.min(configAmount, 1000)
end

function update(dt)
	if world.entityType(entity.id())=="player" then
		for _, entityID in pairs (world.itemDropQuery(entity.position(), 5)) do
			if world.entityName(entityID) == item then
				return
			end
		end
		if count and count < maxAmount then
			world.spawnItem(item, entity.position(), math.min(configAmount, maxAmount - count), {price = 0})
		end

		script.setUpdateDelta(baseRefresh*(1+afkLevel()))
	end
end

function afkLevel()
	return ((status.statusProperty("fu_afk_360s") and 3) or (status.statusProperty("fu_afk_240s") and 2) or (status.statusProperty("fu_afk_120s") and 1) or 0)
end