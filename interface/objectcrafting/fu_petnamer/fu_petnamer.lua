require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/companions/util.lua"
require "/scripts/messageutil.lua"

function init()
	acceptedItems = config.getParameter("acceptedItems")
	if not config.getParameter("moddedCaptureSupport") then
		petCaptureWhitelist = config.getParameter("petCaptureWhitelist")
	end
end

function update(dt)
	promises:update()
	if processing then
		if pod then
			item.parameters = util.mergeTable(item.parameters, createFilledPod(pod).parameters)
			renamePet()
			createNewItem()
			processing = false
		end
	end
end

function petHouseButton()
	container = pane.containerEntityId()
	item = world.containerItemAt(container, 0)
	if item then
		acceptedItem = acceptedItems[item.name]
		if acceptedItem then
			if item.count == 1 then
				if type(acceptedItem) == "string" then
					item.name = acceptedItem
					processing = true
					promises:add(world.sendEntityMessage(container, "getPetInfo"), function (petInfo)
						if not petCaptureWhitelist or petCaptureWhitelist[petInfo.petType] then
							promises:add(world.sendEntityMessage(petInfo.petId, "pet.attemptCapture"), function (pet)
								pod = pet
							end, function ()
								widget.setText("nameTextbox", "Incompatible Mod Detected")
							end)
						else
							widget.setText("nameTextbox", "The BYOS Moded Race Support Patch Is Required For Modded Pets")
						end
					end)
				else
					renamePet()
					createNewItem()
				end
			end
		end
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