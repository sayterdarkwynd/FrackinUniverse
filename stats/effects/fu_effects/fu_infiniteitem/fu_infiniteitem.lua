function init()
	baseRefresh=config.getParameter("refresh")/60.0
	item = config.getParameter("item")
	maxAmount = config.getParameter("maxAmount")
	configAmount = config.getParameter("amount")
	maxDrop = math.min(configAmount, 1000)
end

function update(dt)
	if world.entityType(entity.id())=="player" then
		if timer==0 then
			for _, entityID in pairs (world.itemDropQuery(entity.position(), 5)) do
				if world.entityName(entityID) == item then
					return
				end
			end
			local count = world.entityHasCountOfItem(entity.id(), item)
			if count and count < maxAmount then
				world.spawnItem(item, entity.position(), math.min(configAmount, maxAmount - count), {price = 0})
			end
			timer=baseRefresh
		else
			if afkLevel() > 3 then
				timer=baseRefresh
			else
				timer=math.max(0,(timer or baseRefresh)-dt)
			end
		end
	end
end

function afkLevel()
	return ((status.statusProperty("fu_afk_720s") and 4) or (status.statusProperty("fu_afk_360s") and 3) or (status.statusProperty("fu_afk_240s") and 2) or (status.statusProperty("fu_afk_120s") and 1) or 0)
end