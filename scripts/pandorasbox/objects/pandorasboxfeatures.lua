function initContainer()
	-- reset shortdescription
	local renamedShortDescription = config.getParameter("renamedShortDescription")
	local shortdescription = getItemConfig(object.name()).shortdescription
	if renamedShortDescription ~= "" and renamedShortDescription ~= nil then
		object.setConfigParameter("shortdescription", renamedShortDescription)
	else
		object.setConfigParameter("shortdescription", shortdescription)
	end

	-- reset inventoryIcon
	object.setConfigParameter("inventoryIcon", getItemConfig(object.name()).inventoryIcon)

	-- handler
	message.setHandler("sortContainer", sortContainer)
	message.setHandler("sortPriority", sortPriority)
	message.setHandler("sortDirection", sortDirection)
	message.setHandler("renameContainer", renameContainer)
	message.setHandler("keepContent", keepContent)
	message.setHandler("interfaceColors", interfaceColors)
	message.setHandler("resetOptions", resetOptions)
	message.setHandler("saveOptions", saveOptions)
	message.setHandler("stackingCanceled", stackingCanceled)
  message.setHandler("swapGender", swapGender)
end


function renameContainer(msg, something, newName)
	if newName == "" then
		newName = getItemConfig(object.name()).shortdescription
		object.setConfigParameter("renamedShortDescription", "")
	else
		object.setConfigParameter("renamedShortDescription", newName)
	end
	object.setConfigParameter("shortdescription", newName)
end


function interfaceColors(msg, something, guiColor)
	object.setConfigParameter("guiColor", guiColor)
end


function stackingCanceled(msg, something, equippedItemsText)
	object.say(equippedItemsText)
end


function resetOptions()
	object.say("Configuration reset!")
end


function saveOptions()
	object.say("Configuration saved!")
end
