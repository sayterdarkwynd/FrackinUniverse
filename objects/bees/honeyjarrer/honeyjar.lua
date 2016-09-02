-- This code relies on scriptDelta(jarrer) == scriptDelta(ind.centrifuge) * craftDelay(ind.centrifuge).
-- If this is not the case, then jars may be produced at a lower rate or not at all.

function init(args)
	self.stash = self.stash or { count = 0 }
	animator.setAnimationState("jar", "idle")
end

function update(dt)
	local contents = world.containerItems(entity.id())
	local ents = world.objectQuery(entity.position(), 5, {name="bees_industrialcentrifuge", order="nearest"})

	if #ents > 0 and world.entityName(ents[1]) == "bees_industrialcentrifuge" then
		local stash = world.callScriptedEntity(ents[1], "drawHoney")

		-- Grab a jar or three from the centrifuge.
		-- The stash will be cleared if the centrifuge hands over nothing twice in a row.
		if stash and stash.type == self.stash.type then
			-- same type
			--sb.logInfo ("got %s for %s", stash.count, stash.type)
			self.stash.count = (self.stash.count or 0) + stash.count
			self.stash.sloppy = nil
		elseif stash then
			-- different type
			--sb.logInfo ("got %s for %s (clearing stash)", stash.count, stash.type)
			self.stash = stash
		elseif self.stash.sloppy then
			-- got nothing twice in a row
			--sb.logInfo ("clearing stash")
			self.stash = { count = 0 }
		else
			-- got nothing
			if not self.stash then self.stash = { count = 0 } end
			self.stash.sloppy = true
		end

		if self.stash.count and self.stash.count > 0 then
			animator.setAnimationState("jar", "working")
		end

		-- So long as the stash count is at least 3 and there is at least one empty honey jar in the jarrer, a full jar will be produced. The stash is then reduced.
		if self.stash.count and self.stash.count >= 3 and world.containerConsume(entity.id(), { name= "emptyhoneyjar", count = 1, data={}}) == true then
			--sb.logInfo ("producing one %s", stash.type)
			local throw = world.containerAddItems(entity.id(), { name = self.stash.type, count = 1, data={}})
			if throw then world.spawnItem(throw, entity.position()) end -- hope that the player or an NPC which collects items is around
			self.stash.count = self.stash.count - 3
		end
	else
		animator.setAnimationState("jar", "idle")
	end
end