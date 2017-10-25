function init()
  script.setUpdateDelta(config.getParameter("refresh"))
end

function update(dt)
    item = config.getParameter("item")
    count = world.entityHasCountOfItem(entity.id(), item)
    maxAmount = config.getParameter("maxAmount")
    configAmount = config.getParameter("amount")
    maxDrop = math.min(configAmount, 1000)
    for _, entityID in pairs (world.itemDropQuery(entity.position(), 5)) do
        if world.itemDropItem(entityID).name == item then
            return
        end
    end
    if count and count < maxAmount then
        world.spawnItem(item, entity.position(), math.min(configAmount, maxAmount - count), {price = 0})
    end
end