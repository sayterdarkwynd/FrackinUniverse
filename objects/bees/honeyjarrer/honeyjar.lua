-- This code relies on scriptDelta(jarrer) == scriptDelta(ind.centrifuge) * craftDelay(ind.centrifuge).
-- If this is not the case, then jars may be produced at a lower rate or not at all.

function init(args)
	storage.combsProcessed = storage.combsProcessed or { count = 0 }
	--sb.logInfo("jarrer: %s", storage.combsProcessed)
	animator.setAnimationState("jar", "idle")
end

function update(dt)
	local contents = world.containerItems(entity.id())
	local ents = world.objectQuery(entity.position(), 5, {name="bees_industrialcentrifuge", order="nearest"})

	if #ents > 0 and world.entityName(ents[1]) == "bees_industrialcentrifuge" then
		local stash = world.callScriptedEntity(ents[1], "drawHoney")

		-- Grab a jar or three from the centrifuge.
		-- The stash will be cleared if the centrifuge hands over nothing twice in a row.
		if stash and stash.type == storage.combsProcessed.type then
			-- same type
			--sb.logInfo ("got %s for %s", stash.count, stash.type)
			storage.combsProcessed.count = (storage.combsProcessed.count or 0) + stash.count
			storage.combsProcessed.sloppy = nil
		elseif stash then
			-- different type
			--sb.logInfo ("got %s for %s (clearing stash)", stash.count, stash.type)
			storage.combsProcessed = stash
		elseif storage.combsProcessed.sloppy then
			-- got nothing twice in a row
			--sb.logInfo ("clearing stash")
			storage.combsProcessed = { count = 0 }
		else
			-- got nothing
			if not storage.combsProcessed then storage.combsProcessed = { count = 0 } end
			storage.combsProcessed.sloppy = true
		end

		if storage.combsProcessed.count and storage.combsProcessed.count > 0 then
			animator.setAnimationState("jar", "working")
		end

		-- So long as the stash count is at least 3 and there is at least one empty honey jar in the jarrer, a full jar will be produced. The stash is then reduced.
		if storage.combsProcessed.count and storage.combsProcessed.count >= 3 and world.containerConsume(entity.id(), { name= "emptyhoneyjar", count = 1, data={}}) == true then
			--sb.logInfo ("producing one %s", stash.type)
			local throw = world.containerAddItems(entity.id(), { name = storage.combsProcessed.type, count = 1, data={}})
			if throw then world.spawnItem(throw, entity.position()) end -- hope that the player or an NPC which collects items is around
			storage.combsProcessed.count = storage.combsProcessed.count - 3
		end
	else
		animator.setAnimationState("jar", "idle")
	end
end