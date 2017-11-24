require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	
end

function update(dt)
	
end

function renamePet()
	container = pane.containerEntityId()
	item = world.containerItemAt(container, 0)
	if item then
		validItem = false
		for _,acceptedItem in pairs (config.getParameter("acceptedItems")) do
			if item.name == acceptedItem then
				validItem = true
				break
			end
		end
		if validItem then
			world.containerConsumeAt(container, 0, 1)
			newName = widget.getText("nameTextbox")
			if newName and newName ~= "" then
				newPodUuid = sb.makeUuid()
				item.parameters.pets[1].name = newName
				item.parameters.pets[1].config.parameters.shortdescription = newName
				if item.parameters.currentPets then
					item.parameters.currentPets[1].name = newName
					item.parameters.currentPets[1].config.parameters.shortdescription = newName
					item.parameters.currentPets[1].podUuid = newPodUuid
				end
				item.parameters.tooltipFields.subtitle = newName
				item.parameters.subtitle = newName
				item.parameters.podUuid = newPodUuid
			end
			world.containerAddItems(container, item)
		end
	end
end