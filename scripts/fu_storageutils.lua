function fu_storeItems(items, avoidSlots, spawnLeftovers)
	local function fu_getOutputSlotsFor(something)
		-- TODO: use world.containerItemsFitWhere? Seems not too useful
		local empty = {} -- empty slots in the outputs
		local slots = {} -- slots with a stack of "something"

		for i = 0, world.containerSize(entity.id()) do -- iterate all output slots
			local stack = world.containerItemAt(entity.id(), i) -- get the stack on i
			if stack then -- not empty
				if stack.name == something then -- its "something"
					table.insert(slots,i) -- possible drop slot
				end
			else -- empty
				table.insert(empty, i)
			end
		end

		for _, e in pairs(empty) do -- add empty slots to the end
			table.insert(slots,e)
		end
		return slots
	end

	local function contains(list, item)
		for _, i in pairs(list) do
			if i == item then return true end
		end
		return false
	end


	if avoidSlots then
		local slots = fu_getOutputSlotsFor(items.name)
		for _, i in pairs(slots) do
			if not contains(avoidSlots, i) then
				items = world.containerPutItemsAt(entity.id(), items, i)
				if items == nil then
					break
				end
			end
		end
	else
		items = world.containerAddItems(entity.id(), items)
	end

	if spawnLeftovers and items and items.count > 0 then
		world.spawnItem(items.name, entity.position(), items.count)
		return nil
	end
	return items
end

function fu_sendItems(node, itemDescriptor)
	-- if connected to an object receiver, try to send the item(s)
	-- Wired Industry's item router is one such device

	-- There is an ambiguity if the receiver returns nil (indicating all items stored)
	-- This is also what is returned if the receive function can not be called...
	local unfail = { name = itemDescriptor.name, count = 0, data = itemDescriptor.data }

	local connectedIds = object.getOutputNodeIds(0)
	for i,j in pairs(connectedIds) do
		-- Wired Industry interop
		if world.getObjectParameter(i, "acceptsItems") then
			-- sb.logInfo ('sending %s to object %s', itemDescriptor, i)
			itemDescriptor = world.callScriptedEntity(i, "receiveItem", itemDescriptor)
			-- sb.logInfo ('result: %s', itemDescriptor)
			if not itemDescriptor or itemDescriptor.count == 0 then break end
		end
	end

	return itemDescriptor or unfail -- deal with that ambiguity, hopefully
end

function fu_sendOrStoreItems(node, itemDescriptor, avoidSlots, spawnLeftovers)
	local remain = fu_sendItems(node, itemDescriptor)
	if remain.count then
		-- some unsent; store locally
		remain = fu_storeItems(remain, avoidSlots, spawnLeftovers)
	end
	return remain
end
