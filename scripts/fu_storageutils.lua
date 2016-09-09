function fu_storeItems(items, avoidSlots, spawnLeftovers)
	local function fu_getOutputSlotsFor(something, avoidSlots)
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

	local slots = fu_getOutputSlotsFor(items.name, avoidSlots)
	for _, i in pairs(slots) do
		if not contains(avoidSlots, i) then
			items = world.containerPutItemsAt(entity.id(), items, i)
			if items == nil then
				break
			end
		end
	end
	if spawnLeftovers and items and items.count > 0 then
		world.spawnItem(items.name, entity.position(), items.count)
		return nil
	end
	return items
end
