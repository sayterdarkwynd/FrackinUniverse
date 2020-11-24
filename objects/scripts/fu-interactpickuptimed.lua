function init()
	if storage.itemHasSpawned == false or storage.itemHasSpawned == nil then
		object.setInteractive(true)
		animator.setAnimationState("interactiveObject", "filled")
		storage.itemHasSpawned = false
	else
		animator.setAnimationState("interactiveObject", "empty")
		object.setInteractive(false)
	end

	self.spawnableItem = config.getParameter("spawnableItem")
	self.timedObject = config.getParameter("timedSpawner")
	self.timer = config.getParameter("waitDuration")
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
	--object.setConfigParameter("breakDropPool", "empty")
end

function onInteraction(args)
	if storage.itemHasSpawned == false then
		open()
	end
end

function update(dt)
        self.timer = self.timer - dt
        if (self.timer < 0) then self.timer = 0 end
	if (self.timedObject == 1) then
	  if self.timer == 0 then
	    self.timer = config.getParameter("waitDuration")  		--reset timer
	    storage.itemHasSpawned = false				--failsafe for item spawn
	    animator.setAnimationState("interactiveObject", "filled")   --set it to active appearance again
	    object.setInteractive(true) 				--make interactive again
	  end
	end
end
