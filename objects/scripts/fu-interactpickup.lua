function init()
	if not storage.itemHasSpawned then
		object.setInteractive(true)
		animator.setAnimationState("interactiveObject", "filled")
		storage.itemHasSpawned = false
	else
		animator.setAnimationState("interactiveObject", "empty")
		object.setInteractive(false)
	end

	self.spawnableItem = config.getParameter("spawnableItem")
	self.timedObject = config.getParameter("timedSpawner")
end

function open()
	animator.setAnimationState("interactiveObject", "empty")
	world.spawnItem(self.spawnableItem, entity.position(), 1)
	if animator.hasSound("pickup") then
		animator.playSound("pickup")
	end
	storage.itemHasSpawned = true
	object.setInteractive(false)

	--Make sure that, if the object is broken after having been collected, nothing drops
	object.setConfigParameter("breakDropPool", "empty")
end

function onInteraction(args)
	if storage.itemHasSpawned == false then
		open()
	end
end

function update(dt)

end
