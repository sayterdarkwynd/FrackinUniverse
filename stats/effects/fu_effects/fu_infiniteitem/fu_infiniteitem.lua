function init()
  self.value = config.getParameter("refresh")
  script.setUpdateDelta(self.value)
end

function update(dt)
	item = config.getParameter("item")
	count = world.entityHasCountOfItem(entity.id(), item)
	maxAmount = config.getParameter("maxAmount")
	if count and count < maxAmount then
		configAmount = config.getParameter("amount")
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
