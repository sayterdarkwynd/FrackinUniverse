function trySendItems(node, itemDescriptor)
	-- if connected to an object receiver, try to send the item(s)
	-- Wired Industry's item router is one such device

	-- There is an ambiguity if the receiver returns nil (indicating all items stored)
	-- This is also what is returned if the receive function can not be called...
	local unfail = { name = itemDescriptor.name, count = 0, data = itemDescriptor.data }

	local connectedIds = object.getOutputNodeIds(0)
	for i,j in pairs(connectedIds) do
		if world.getObjectParameter(i, "acceptsItems") then
			-- sb.logInfo ('sending %s to object %s', itemDescriptor, i)
			itemDescriptor = world.callScriptedEntity(i, "receiveItem", itemDescriptor)
			-- sb.logInfo ('result: %s', itemDescriptor)
			if not itemDescriptor or itemDescriptor.count == 0 then break end
		end
	end

	return itemDescriptor or unfail -- deal with that ambiguity, hopefully
end
