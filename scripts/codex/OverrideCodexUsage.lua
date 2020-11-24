local LastUsedFiringState = false

function TryGetPlayerId()
	local target = fireableItem.ownerAimPosition()
	local entities = world.playerQuery(target, 256)

	local playerId
	if #entities == 1 then
		sb.logInfo("One player entity located. Directly referencing.")
		playerId = entities[1]
	elseif #entities > 1 then
		sb.logInfo("More than one player entity located. Checking player held items...")
		for _, id in ipairs(entities) do
			local itemL = world.entityHandItem(id, "primary")
			local itemR = world.entityHandItem(id, "alt")

			if itemL == item.name() or itemR == item.name() then
				sb.logInfo("Player " .. tostring(id) .. " is holding an item with this item's name. Assuming this is the right player. This might be inaccurate!")
				playerId = id
				break
			end
		end
	else
		sb.logWarn("No player found in player query!")
	end

	return playerId
end

function activate()
	--sb.logInfo("This item is: " .. tostring(item.name()))

	local playerId = TryGetPlayerId()
	if not playerId then return end

	--sb.logInfo("I am " .. tostring(playerId))
	--sb.logInfo(tostring(world.entityUniqueId(playerId)))

	world.sendEntityMessage(playerId, "xcodexLearnCodex", item.name()) -- This has the "-codex"
	sb.logInfo("Sent message.")
end

function update()
	if not LastUsedFiringState and fireableItem.firing() then
		activate()
		LastUsedFiringState = true
	end

	if not fireableItem.firing() then
		LastUsedFiringState = false
	end
end
