require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
	raceInfo = root.assetJson("/interface/objectcrafting/fu_racialiser/fu_raceinfo.config")
    count = 1
	itemType = nil
	raceAmount = raceAmount()
	change = 1
	itemNew = reload()
end

function update(dt)
	item = root.itemConfig(world.containerItemAt(pane.containerEntityId(),0))
	if item then
		itemType = item.config.racialiserType
	else
		itemType = nil
	end
	itemNew = reload()
end

function raceAmount()
	raceCount = 0
	for _, _ in pairs (raceInfo) do
		raceCount = raceCount + 1
	end
	return raceCount
end

function reload()
	if itemType then
		info = raceInfo[count]
		value = info[itemType]
			if itemType == "pet" then
				if value.unique and root.itemConfig(info.techstation.name) then
					widget.setText("lblText", info.petName)
					return nil
				end
			elseif value.unique and root.itemConfig(value.name) then
				widget.setText("lblText", info.name)
				return value
			end
		changeRace()
	end
	widget.setText("lblText", "")
end

function nextRace()
	change = 1
	changeRace()
end

function previousRace()
	change = -1
	changeRace()
end

function changeRace()
	count = count + change
	if count < 1 then
		count = raceAmount
	elseif count > raceAmount then
		count = 1
	end
end

function racialise()
	if itemType then
		itemOld = world.containerItemAt(pane.containerEntityId(),0)
		world.containerTakeAt(pane.containerEntityId(),0)
		world.containerAddItems(pane.containerEntityId(), {name = itemOld.name, count = itemOld.count, parameters = getNewParameters(root.itemConfig(itemOld).config.shipPetType)})
	end
end

function getNewParameters(pet, treasure)
	itemConfig = root.itemConfig(itemNew)
	info = raceInfo[count]
	newParameters = {}
	if itemConfig then
		if item then
			shortDescriptionNew = item.config.shortdescription .. " (" .. info.name .. ")"
			newParameters = util.mergeTable(newParameters, {shortdescription = shortDescriptionNew})
		end
		inventoryIconNew = itemConfig.directory .. itemConfig.config.inventoryIcon
		newParameters = util.mergeTable(newParameters, {inventoryIcon = inventoryIconNew})
		orientationsNew, placementImageNew, placementImagePositionNew = getNewOrientations()
		newParameters = util.mergeTable(newParameters, {imageConfig = orientationsNew, placementImage = placementImageNew, placementImagePosition = placementImagePositionNew})
		imageFlippedNew = itemConfig.config.sitFlipDirection
		newParameters = util.mergeTable(newParameters, {imageFlipped = imageFlippedNew})
		dialogNew = itemConfig.config.dialog
		newParameters = util.mergeTable(newParameters, {dialog = dialogNew})
	end
	if pet then
		if not itemConfig and item then
			shortDescriptionNew = item.config.shortdescription .. " (" .. info.petName .. ")"
			newParameters = util.mergeTable(newParameters, {shortdescription = shortDescriptionNew})
		end
		petNew = info.pet.name
		newParameters = util.mergeTable(newParameters, {shipPetType = petNew})
	end
	if treasure then
		treasurePoolsNew = info.starterTreasure.name
		newParameters = util.mergeTable(newParameters, {treasurePools = {treasurePoolsNew}})
	end
	return newParameters
end

function getNewOrientations()
	newPlacementImage = nil
	newOrientations = itemConfig.config.orientations
	for num, _ in pairs (newOrientations) do
		imageLayers = newOrientations[num].imageLayers
		if imageLayers then
			for num2, _ in pairs (imageLayers) do
				imageLayer = imageLayers[num2].image
				newOrientations[num].imageLayers[num2].image = itemConfig.directory .. imageLayer
				if not newPlacementImage then
					newPlacementImage = newOrientations[num].imageLayers[num2].image:gsub("<frame>", 1):gsub("<color>", "default"):gsub("<key>", 1)
				end
			end
		end
		dualImage = newOrientations[num].dualImage
		if dualImage then
			newOrientations[num].dualImage = itemConfig.directory .. dualImage
			if not newPlacementImage then
				newPlacementImage = newOrientations[num].dualImage:gsub("<frame>", 1):gsub("<color>", "default"):gsub("<key>", 1)
			end
		end
		image = newOrientations[num].image
		if image and not imageLayers then --Avali teleporter fix
			newOrientations[num].image = itemConfig.directory .. image
			if not newPlacementImage then
				newPlacementImage = newOrientations[num].image:gsub("<frame>", 1):gsub("<color>", "default"):gsub("<key>", 1)
			end
		end
		if not newPlacementImagePosition then
			newPlacementImagePosition = newOrientations[num].imagePosition
		end
	end
	positionOverride = info[itemType].positionOverride
	if positionOverride then
		newOrientations[1].imagePosition = positionOverride
		newPlacementImagePosition = positionOverride
	end
	return newOrientations, newPlacementImage, newPlacementImagePosition
end

function getBYOSParameters(BYOSItemType, pet, treasure) --figure out how to give them the name change
	itemType = BYOSItemType
	if itemType then
		info = raceInfo[count]
		value = info[itemType]
		if root.itemConfig(value.name) then
			itemNew = value
		end
	end
	return getNewParameters(pet, treasure)
end