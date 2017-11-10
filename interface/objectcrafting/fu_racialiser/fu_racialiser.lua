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
		for num, info in pairs (raceInfo) do
			if num == count then
				for key, value in pairs (info) do
					if key == itemType then
						if itemType == "pet" then
							if value.unique and root.itemConfig(info.techstation.name) then
								widget.setText("lblText", info.petName)
								return nil
							end
						elseif value.unique and root.itemConfig(value.name) then
							widget.setText("lblText", info.name)
							return value
						end
					end
				end
				changeRace()
			end
		end
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
	newParameters = {}
	if itemConfig then
		inventoryIconNew = itemConfig.directory .. itemConfig.config.inventoryIcon
		newParameters = util.mergeTable(newParameters, {inventoryIcon = inventoryIconNew})
		orientationsNew = itemConfig.config.orientations
		newParameters = util.mergeTable(newParameters, {orientations = orientationsNew})
	end
	if pet then
		for num, info in pairs (raceInfo) do
			if num == count then
				newPet = info.pet.name
				break
			end
		end
		newParameters = util.mergeTable(newParameters, {shipPetType = newPet})
	end
	if treasure then
		for num, info in pairs (raceInfo) do
			if num == count then
				newTreasurePools = info.starterTreasure.name
				break
			end
		end
		newParameters = util.mergeTable(newParameters, {treasurePools = {newTreasurePools}})
	end
	return newParameters
end