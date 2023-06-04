function keepContent(msg, something, keepContent)
	if keepContent == true then
		object.setConfigParameter("keepContent", true)
	else
		object.setConfigParameter("keepContent", false)
	end
end


function placeItems()
	-- fill container with content
	if storage.init == nil then
		local content = config.getParameter("content")
		if content then
			for position, item in pairs(content) do
				world.containerPutItemsAt(entity.id(), item, position-1)
			end
		end
		storage.init = true
	end
end


function smashContainer(objectType)
	local defaultSlotCount = getItemConfig(object.name()).slotCount
	local slotCount = config.getParameter("slotCount")
	local keepContent = config.getParameter("keepContent")
	local guiColor = config.getParameter("guiColor")
	local inventoryIcon = config.getParameter("inventoryIcon")
	local renamedShortDescription = config.getParameter("renamedShortDescription")
	local content = world.containerItems(entity.id())
	local objParameters = {}
	local description = ""
	local shortdescription
	local usedSlots = 0

	-- guiColor - Color
	if guiColor then
		objParameters["guiColor"] = guiColor
	end

	-- shortdescription text
	if renamedShortDescription and renamedShortDescription ~= "" then
		shortdescription = renamedShortDescription
		objParameters["renamedShortDescription"] = renamedShortDescription
		objParameters["shortdescription"] = shortdescription
	else
		shortdescription = getItemConfig(object.name()).shortdescription
	end

	-- slot count
	if slotCount ~= defaultSlotCount then
		objParameters["slotCount"] = slotCount

		shortdescription = shortdescription .. " ^yellow;^reset;"
		objParameters["shortdescription"] = shortdescription
	end

	-- store content
	if keepContent == true or (config.getParameter("content") and keepContent == nil) then
		world.containerTakeAll(entity.id())

		-- container has content?
		if next(content) ~= nil then
			local price = getItemConfig(object.name()).price or 0
			for position, item in pairs(content) do
				usedSlots = usedSlots + 1

				-- another container with content inside?
				if item.parameters and item.parameters.content and next(item.parameters.content) ~= nil then
					-- sb.logInfo("item.parameters: %s", item.parameters)
					world.spawnItem(item, entity.position(), 1, item.parameters)
					content[position] = nil
					usedSlots = usedSlots - 1
				else
					price = price + getItemConfig(item).price * item.count
					description = description.."^green;^reset; " .. getItemConfig(item).shortdescription.."\n"
				end
			end

			description = (objectType == "mannequin") and description or "^green;^reset; " .. usedSlots .. " / " .. world.containerSize(entity.id()) .. " slots used"

			if usedSlots > 0 then
				objParameters["price"] = price
				objParameters["content"] = content
				objParameters["inventoryIcon"] = inventoryIcon .. "?border=1;00FF00?fade=007800;0.1"
				objParameters["shortdescription"] = shortdescription .. " ^green;^reset;"
				objParameters["description"] = description
			end
		end
	end

	-- save keepContent if objParameters or checkbox unchecked
	if next(objParameters) ~= nil or keepContent == false then
		objParameters["keepContent"] = keepContent
	end

	object.smash(true)
	world.spawnItem(object.name(), entity.position(), 1, objParameters)
end
