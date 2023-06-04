require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()

end

function update(dt)

end

function renameButton()
	container = pane.containerEntityId()
	item = world.containerItemAt(container, 0) or {}
	if item.parameters and item.parameters.podUuid then
		renamePet()
		createNewItem()
	end
end

function renamePet()
	textboxName = widget.getText("nameTextbox")
	if not item.parameters.pets[1].config.parameters.monsterTypeName then
		item.parameters.pets[1].config.parameters.monsterTypeName = item.parameters.pets[1].name
		if item.parameters.currentPets then
			item.parameters.currentPets[1].config.parameters.monsterTypeName = item.parameters.pets[1].name
		end
	end
	if textboxName and textboxName == "" then
		newName = item.parameters.pets[1].config.parameters.monsterTypeName
	else
		newName = textboxName
	end
	if newName then
		item.parameters.pets[1].name = newName
		item.parameters.pets[1].config.parameters.shortdescription = newName
		if item.parameters.currentPets then
			item.parameters.currentPets[1].name = newName
			item.parameters.currentPets[1].config.parameters.shortdescription = newName
		end
		item.parameters.tooltipFields.subtitle = newName
		item.parameters.subtitle = newName
		item.parameters.podItemHasPriority = true
	end
end

function createNewItem()
	world.containerConsumeAt(container, 0, 1)
	world.containerAddItems(container, item)
end