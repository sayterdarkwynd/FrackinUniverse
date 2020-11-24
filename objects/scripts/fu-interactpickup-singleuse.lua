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
	--self.timedObject = config.getParameter("timedSpawner")
end

function open(cheezit)
	if not cheezit then
		world.spawnItem(self.spawnableItem, entity.position(), 1)
		if animator.hasSound("pickup") then
			animator.playSound("pickup")
		end
	end
	animator.setAnimationState("interactiveObject", "empty")
	storage.itemHasSpawned = true
	object.setInteractive(false)

	--Make sure that, if the object is broken after having been collected, nothing drops
	object.setConfigParameter("breakDropPool", "empty")
end

function update(dt)
	if not storage.itemHasSpawned then
		if self.itemCheck then
			if self.itemCheck:finished() then
				if self.itemCheck:succeeded() then
					open(self.itemCheck:result())
				end
				self.itemCheck=nil
			elseif self.itemCheckTimeout and self.itemCheckTimeout >= 5 then
				self.itemCheck=nil
			else
				self.itemCheckTimeout = (self.itemCheckTimeout or 0) + dt
			end
		end
	end
end

function onInteraction(args)
	if (not self.itemHasSpawned) and (not self.itemCheck) then
		if world.entityType(args.sourceId)=="player" then
			self.itemCheck=world.sendEntityMessage(args.sourceId,"player.hasItem",self.spawnableItem)
		end
	end
end