require "/scripts/util.lua"
require "/scripts/messageutil.lua"
require "/scripts/companions/util.lua"

function init()
	petList = getPetList()
	containerId = config.getParameter("containerId") or pane.containerEntityId()
	baseButtonTimer = config.getParameter("buttonTimer", 1)
	buttonTimer = baseButtonTimer
	popupMessages = config.getParameter("popupMessages", {})
	interactionTypes = config.getParameter("interactionTypes")
	resetAddedPetsConfirmation = config.getParameter("resetAddedPetsConfirmation")
	updatePetParams()
end

function petListSelected()
	local listSelected = widget.getListSelected("petList.petList")
	if listSelected then
		local listData = widget.getData("petList.petList." .. listSelected)
		if listData then
			world.sendEntityMessage(containerId, "setShipPet", listData.pet)
		end
	end
end

function updatePetParams()
	promises:add(world.sendEntityMessage(containerId, "getPetParams"), function(petParamaters)
		petParams = petParamaters
		populateList()
		widget.setText("petName", petParams.shortdescription or "")
		local petInteractionType = petParams.interactionType or "timer"
		for num, interactionTypeData in ipairs (interactionTypes) do
			if interactionTypeData.type == petInteractionType then
				widget.setText("interactionType", interactionTypeData.name or "")
				interactionTypeNum = num
				break
			end
		end
		setFoodLikings(petParams.foodLikings)
	end, function()
		player.interact("ShowPopup", {message = popupMessages.invalidTechstation or ""})
		pane.dismiss()
	end)
end

function populateList()
	widget.clearListItems("petList.petList")
	local petArray = {}
	for pet, techstation in pairs (petList) do
		if root.itemConfig(techstation) then
			table.insert(petArray, pet)
		end
	end
	table.sort(petArray)
	local currentPet = world.getObjectParameter(containerId, "shipPetType")
	for _, pet in ipairs (petArray) do
		local listItem = "petList.petList." .. widget.addListItem("petList.petList")
		widget.setText(listItem .. ".name", pet)
		widget.setImage(listItem .. ".icon", root.monsterPortrait(pet, petParams)[1].image)
		widget.setData(listItem, {pet = pet})
		if pet == currentPet then
			widget.setListSelected("petList.petList", listItem:gsub("petList.petList.", ""))	--Make it not need to use gsub
		end
	end
end

function update(dt)
	promises:update()

	if buttonTimer > 0  then
		buttonTimer = buttonTimer - dt
	end
end

function getPetList()
	petListTemp = {}
	local races = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
	local raceTableOverride = root.assetJson("/frackinship/configs/racetableoverride.config")
	for _, race in pairs (races) do
		if raceTableOverride[race] and raceTableOverride[race].race then
			race = raceTableOverride[race].race
		end
		local techstation = race .. "techstation"
		if raceTableOverride[race] and raceTableOverride[race].items then
			for item, _ in pairs (raceTableOverride[race].items) do
				if string.find(item, "techstation") then
					techstation = item
					break
				end
			end
		end
		local techstationInfo = root.itemConfig(techstation)
		if techstationInfo and techstationInfo.config.shipPetType then
			local shipPetType = techstationInfo.config.shipPetType
			if not petListTemp[shipPetType] then
				petListTemp[shipPetType] = techstation
			end
		end
	end

	petListTemp = util.mergeTable(status.statusProperty("fu_byospethouseAddedPets", {}), petListTemp)
	petListTemp = util.mergeTable(root.assetJson("/frackinship/configs/nontechstationshippetlist.config"), petListTemp)

	return petListTemp
end

function petNameChange()
	local petName = widget.getText("petName")
	world.sendEntityMessage(containerId, "setPetName", petName)
end

function randomiseSeed()
	if buttonTimer <= 0 then
		world.sendEntityMessage(containerId, "randomiseSeed", generateSeed())
		updatePetParams()
		buttonTimer = baseButtonTimer
	end
end

function capturePet()
	if buttonTimer <= 0 then
		if player.hasItem("capturepod") then
			promises:add(world.sendEntityMessage(containerId, "getPetId"), function(petId)
				if petId and world.entityExists(petId) then
					promises:add(world.sendEntityMessage(petId, "pet.attemptCapture"), function(pet)
						if pet then
							if player.consumeItem({name = "capturepod", count = 1}) then
								petName = widget.getText("petName")
								if petName == "" then
									petName = pet.name
								end
								pet.name = petName
								pet.config.parameters.shortdescription = petName
								pet.config.parameters.monsterTypeName = world.getObjectParameter(containerId, "shipPetType")
								local pod = createFilledPod(pet)
								world.spawnItem(pod, world.entityPosition(containerId))
								world.sendEntityMessage(containerId, "resetPet", generateSeed())
								updatePetParams()
							else
								player.interact("ShowPopup", {message = popupMessages.noPod or ""})
							end
						else
							player.interact("ShowPopup", {message = popupMessages.captureFail or ""})
						end
					end, function()
						player.interact("ShowPopup", {message = popupMessages.captureFail or ""})
					end)
				else
					player.interact("ShowPopup", {message = popupMessages.petMissing or ""})
				end
			end)
		else
			player.interact("ShowPopup", {message = popupMessages.noPod or ""})
		end
		buttonTimer = baseButtonTimer
	end
end

function changeObjectPet()
	if buttonTimer <= 0 then
		local item = widget.itemGridItems("itemGrid")[1]
		if item then
			local itemCfg = root.itemConfig(item.name).config
			local itemPet = item.parameters.shipPetType or itemCfg.shipPetType
			if itemPet and item.name ~= "fu_byospethouse" then
				item.parameters.shipPetType = world.getObjectParameter(containerId, "shipPetType")
				item.parameters.description = itemCfg.description .. " Spawns a " .. world.getObjectParameter(containerId, "shipPetType") .. "."
				world.containerSwapItemsNoCombine(containerId, item, 0)
			end
		end
		buttonTimer = baseButtonTimer
	end
end

function addObjectPetToList()
	if buttonTimer <= 0 then
		local item = widget.itemGridItems("itemGrid")[1]
		if item then
			local itemCfg = root.itemConfig(item.name).config
			local itemPet = item.parameters.shipPetType or itemCfg.shipPetType
			if itemPet and item.name ~= "fu_byospethouse" then
				if not petList[itemPet] then
					local addedPets = status.statusProperty("fu_byospethouseAddedPets", {})
					local petObject = item.parameters.racialisedTo or item.name
					addedPets[itemPet] = petObject
					petList[itemPet] = petObject
					status.setStatusProperty("fu_byospethouseAddedPets", addedPets)
					populateList()
				end
			end
		end
		buttonTimer = baseButtonTimer
	end
end

function cycleInteractionType(button)
	if interactionTypeNum then
		local cycleDirection = widget.getData(button).direction
		interactionTypeNum = interactionTypeNum + cycleDirection
		if interactionTypeNum > #interactionTypes then
			interactionTypeNum = 1
		elseif interactionTypeNum < 1 then
			interactionTypeNum = #interactionTypes
		end
		local interactionTypeData = interactionTypes[interactionTypeNum]
		world.sendEntityMessage(containerId, "changeInteractionType", interactionTypeData.type)
		widget.setText("interactionType", interactionTypeData.name or "")
	end
end

function setFoodLikings(foodLikings)
	widget.clearListItems("foodLikings.foodList")
	if foodLikings then
		local foodArray = {}
		local foodTable = {}
		for food, liking in pairs (foodLikings) do
			local foodCfg = root.itemConfig(food)
			if foodCfg then
				local foodName = foodCfg.config.shortdescription
				table.insert(foodArray, foodName)
				foodTable[foodName] = liking
			end
		end
		table.sort(foodArray)
		for _, food in ipairs (foodArray) do
			local listItem = "foodLikings.foodList." .. widget.addListItem("foodLikings.foodList")
			local listText = food .. ": " .. foodTable[food] .. "%"
			widget.setText(listItem .. ".food", listText)
		end
	end
end

function resetAddedPets()
	if buttonTimer <= 0 then
		promises:add(player.confirm(resetAddedPetsConfirmation), function (choice)
			if choice then
				status.setStatusProperty("fu_byospethouseAddedPets", {})
				petList = getPetList()
				updatePetParams()
			end
		end)
		buttonTimer = baseButtonTimer
	end
end
