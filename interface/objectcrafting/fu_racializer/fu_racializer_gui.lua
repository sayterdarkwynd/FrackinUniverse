require "/scripts/util.lua"
require "/scripts/interp.lua"

local itemOld = nil
local itemOldCfg = nil
local itemNew = nil
local itemPGI = nil
local cost = 0

-- Table of allowed objects.
local raceTable

function init()
  self.baseCost = config.getParameter("cost", 100)
  self.costModifier = config.getParameter("costModifier", 4)
  self.itemConversions = config.getParameter("objectConversions", {})
  self.newItem = {}
  self.raceTableOverride = root.assetJson("/frackinship/configs/racetableoverride.config")
  self.useAll = true
  raceTable = buildRaceTable()
  populateList()
  widget.setButtonEnabled("btnConvert",false)
end

function populateList()
  self.raceList = "scr_raceList.raceList"
  self.selectedText = nil

  widget.clearListItems(self.raceList)
  local raceArray = {}
  for race, _ in pairs (raceTable) do
    table.insert(raceArray, race)
  end
  table.sort(raceArray, function(raceA, raceB)
	a = raceTable[raceA].name or raceA
	b = raceTable[raceB].name or raceB
	return a < b
  end)
  for _, race in ipairs (raceArray) do
	if race ~= "fu_byos" then
      local item = string.format("%s.%s", self.raceList, widget.addListItem(self.raceList))
	  widget.setText(string.format("%s.title", item), raceTable[race].name or race)
      widget.setImage(string.format("%s.icon", item), "/interface/title/"..raceTable[race].icon)
      widget.setData(item, {title = race})
	end
  end
end

function update(dt)
    local setCost = true

    itemOld = world.containerItemAt(pane.containerEntityId(),0)
    itemPGI = world.containerItemAt(pane.containerEntityId(),1)
    ItemNew = world.containerItemAt(pane.containerEntityId(),2)

    cost = self.baseCost

    if itemPGI then
        --Validate slot#2 contains a PGI
        local cfg = root.itemConfig(itemPGI).config
        if cfg.objectName ~= "perfectlygenericitem" then
            itemPGI = nil
        end
    end

	if itemPGI == nil then
		cost = round(cost * self.costModifier,0)
    end

    if itemOld and itemOld.name ~= oldItemOld then	--Prevent checking every update
        --Validate slot#1 contains a racial item (exists in the above table)
		local itemOldInfo = root.itemConfig(itemOld)
        itemOldCfg = itemOldInfo.config
		itemOldRace = itemOldCfg.objectName:gsub("captainschair", ""):gsub("fuelhatch", ""):gsub("shipdoor", ""):gsub("shiphatch", ""):gsub("shiplocker", ""):gsub("techstation", ""):gsub("teleporter", ""):gsub("deco", ""):gsub("crew", "")		--Figure out a better way to handle "deco" and "crew" objects
		if itemOldRace == "" then
			itemOldRace = "apex"
		end
        --sb.logInfo(itemOldCfg.objectName)
        --sb.logInfo(itemOldCfg.race)
        --sb.logInfo(raceStr)
        if raceTable[itemOldRace] and raceTable[itemOldRace]["items"][itemOldCfg.objectName] then
			local oldObjectCfg = util.mergeTable(itemOldCfg, itemOld.parameters)
            widget.setImage("imgPreviewIn", oldObjectCfg.placementImage or getPlacementImage(oldObjectCfg.imageConfig or oldObjectCfg.defaultImageConfig or oldObjectCfg.orientations, itemOldInfo.directory))
            widget.setText(string.format("%s",  "races1Label"), "Supported Races  |  Input: "..raceTable[itemOldRace].name or itemOldRace)
			oldItemOld = itemOld.name
			self.newName = nil
			self.newItem = {}
			raceList_SelectedChanged()
        else
            widget.setImage("imgPreviewIn", "")
			widget.setImage("imgPreviewOut", "")
			widget.setText("lblCost", "Cost:   x--")
			widget.setText("preview_lbl2", "Output: --")
			widget.setText("races1Label", "Supported Races  |  Input: --")
			itemOld = nil
			setCost = false
			oldItemOld = nil
			self.newName = nil
			self.newItem = {}
        end
    elseif not itemOld or itemOld.name ~= oldItemOld then
        widget.setImage("imgPreviewIn", "")
        widget.setImage("imgPreviewOut", "")
        widget.setText("lblCost", "Cost:   x--")
        widget.setText("preview_lbl2", "Output: --")
		widget.setText("races1Label", "Supported Races  |  Input: --")
        setCost = false
		oldItemOld = nil
		self.newName = nil
		self.newItem = {}
    end

    if not self.newName then
        setCost = false
    end

	if setCost == true then
		updateCostLbl()
    elseif setCost == false then
        widget.setButtonEnabled("btnConvert",false)
    end
end

-- updates the cost label text.
function updateCostLbl()
	if self.useAll == true then
		widget.setText("lblCost", "Cost:   x"..cost * itemOld.count)
	else
		widget.setText("lblCost", "Cost:   x"..cost)
	end

	if world.getObjectParameter(pane.containerEntityId(), "racialising") then
		widget.setButtonEnabled("btnConvert",false)
	elseif ItemNew then
		widget.setButtonEnabled("btnConvert",false)			--Eventually make this take into account whether the item can actually fit
	else
		widget.setButtonEnabled("btnConvert",true)
	end
end

function btnConvert_Clicked()
	--ItemDescriptor world.containerTakeAt(EntityId entityId, unsigned offset)
	--ItemDescriptor world.containerTakeNumItemsAt(EntityId entityId, unsigned offset, unsigned count)
	local doCraft = true
	local totalCost = cost * itemOld.count

	if player.currency("money") < totalCost then doCraft=false end
	if itemPGI then -- ughh.. check if set first before checking count.
		if itemOld.count > itemPGI.count and self.useAll == true then doCraft = false end
	end

	--start crafting if true, otherwise play error sound and return
	if doCraft == true then
		if self.useAll == true then newCount = itemOld.count else newCount = 1 end
		--Create new item
		itemNew = {name = self.newItem.type, count = newCount, parameters = {}}
		itemNew.parameters = itemOld.parameters
		itemNew.parameters.shortdescription = self.newItem.name
		itemNew.parameters.shipPetType = itemNewInfo.config.shipPetType
		itemNew.parameters.orientations = nil
		itemNew.parameters.racialisedTo = self.newName
		if itemNewInfo.config.animationCustom and itemNewInfo.config.animationCustom.sounds then
			if itemNewInfo.config.animationCustom.sounds.open and itemNewInfo.config.animationCustom.sounds.open.pool then
				itemNew.parameters.customSoundsOpen = itemNewInfo.config.animationCustom.sounds.open.pool
			end
			if itemNewInfo.config.animationCustom.sounds.close and itemNewInfo.config.animationCustom.sounds.close.pool then
				itemNew.parameters.customSoundsClose = itemNewInfo.config.animationCustom.sounds.close.pool
			end
		end

		itemNew.parameters = util.mergeTable(itemNew.parameters, getNewParameters(itemNewInfo, self.newItem.positionOverride))

		if self.useAll == true then
			world.containerTakeAt(pane.containerEntityId(), 0)
			if itemPGI then
				if itemOld.count == itemPGI.count then
					world.containerTakeAt(pane.containerEntityId(), 1)
				else
					world.containerTakeNumItemsAt(pane.containerEntityId(), 1, itemOld.count)
				end
			end
		elseif self.useAll == false then
			world.containerTakeNumItemsAt(pane.containerEntityId(), 0, 1)
			if itemPGI then
				world.containerTakeNumItemsAt(pane.containerEntityId(), 1, 1)
			end
		end

		player.consumeCurrency("money", totalCost)
		widget.playSound("/sfx/interface/fu_racializer_working.ogg", 0, 1.5)
		world.sendEntityMessage(pane.containerEntityId(), "doWorkAnim")
		world.sendEntityMessage(pane.containerEntityId(), "startRacialising", {itemNew= itemNew, itemOld = itemOld, itemPGI = itemPGI, cost = totalCost})
	else
		itemNew = nil --reset
		widget.playSound("/sfx/interface/clickon_error.ogg", 0, 1.25)
	end
end

function btnUseAll_Clicked(widgetName)
	if widget.getChecked(tostring(widgetName)) == true then
		self.useAll = true
	else
		self.useAll = false
	end
	if itemOld then
		updateCostLbl()
	end
end

function round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  mult = math.floor(num * mult + 0.5) / mult
  return math.floor(mult) -- Do it again to remove the decimal point (why is this even needed??)
end

--Update selectedText variable
function raceList_SelectedChanged()
    local listItem = widget.getListSelected(self.raceList)
    if listItem then
        local itemData = widget.getData(string.format("%s.%s", self.raceList, listItem))
        if itemData then
            self.selectedText = itemData.title
            if (itemOld and itemPGI and self.selectedText) or ((itemOld and not itemPGI) and self.selectedText) then
                --update the preview output image with the value of the associated race.
                widget.setText(string.format("%s",  "preview_lbl2"), "Output ("..(raceTable[self.selectedText].name or self.selectedText)..")" )
                local oldName = itemOldCfg.objectName
                local oldRace = itemOldRace
                local base = oldName:gsub(oldRace, ""):gsub("deco", ""):gsub("crew", "")		--Figure out a better way to handle "deco" and "crew" objects
                self.newName = self.selectedText..base
				self.newItem.type = self.itemConversions[oldName] or self.itemConversions[base]
				self.newItem.name = root.itemConfig(self.newItem.type).config.shortdescription.. " (" .. (raceTable[self.selectedText].name or self.selectedText) .. ")"
				local newItemData = raceTable[self.selectedText].items[self.newName]
				if type(newItemData) == "table" then
					self.newItem.positionOverride = newItemData
				else
					self.newItem.positionOverride = nil
				end
                --sb.logInfo(base)
                --sb.logInfo(self.newName)
				itemNewInfo = root.itemConfig(self.newName) or {}
				local itemNewCfg = itemNewInfo.config
				if itemNewCfg then
					widget.setImage("imgPreviewOut", itemNewCfg.placementImage or getPlacementImage(itemNewCfg.orientations, itemNewInfo.directory))
				else
					for item, data in pairs (raceTable[self.selectedText].items) do
						if string.find(item, base) then
							self.newName = item
							if type(data) == "table" then
								self.newItem.positionOverride = newItemData
							else
								self.newItem.positionOverride = nil
							end
						end
					end
					itemNewInfo = root.itemConfig(self.newName) or {}
					local itemNewCfg = itemNewInfo.config
					if itemNewCfg then
						widget.setImage("imgPreviewOut", getPlacementImage(itemNewCfg.orientations, itemNewInfo.directory))
					else
						self.newName = false
						widget.setImage("imgPreviewOut", "")
						widget.setText(string.format("%s",  "preview_lbl2"), "Output: --")
						widget.setText("lblCost", "Cost:   x--")
					end
				end
            end
        else
            self.selectedText = "itemData not set" --in case something went wrong
        end
    end
end

function buildRaceTable()
	local tempRaceTable = {}
	local raceObjects = config.getParameter("raceObjects")
	local races = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
	for _, race in pairs (races) do
		local succeded, raceData = pcall(root.assetJson, "/species/" .. race .. ".species")
		if self.raceTableOverride[race] and self.raceTableOverride[race].race then
			race = self.raceTableOverride[race].race
		end
		tempRaceTable[race] = {}
		tempRaceTable[race].icon = race .. "male.png"
		if succeded and raceData and raceData.charCreationTooltip then
			tempRaceTable[race].name = raceData.charCreationTooltip.title
		end
		tempRaceTable[race].items = {}
		for _, objectType in pairs (raceObjects) do
			local objectInfo = root.itemConfig(race .. objectType)
			if objectInfo then
				tempRaceTable[race].items[race .. objectType] = true
			end
		end
		local hasObjects = false
		for object, _ in pairs (tempRaceTable[race].items) do
			hasObjects = true
			break
		end
		if not hasObjects then
			tempRaceTable[race] = nil
			--sb.logInfo("Removing " .. tostring(race))
		end
	end
	for race, info in pairs (self.raceTableOverride) do
		if race == "fu_byos" then
			tempRaceTable[race] = {items = {}}
		end
		if tempRaceTable[race] then
			tempRaceTable[race].icon = info.icon or tempRaceTable[race].icon
			tempRaceTable[race].name = info.name or tempRaceTable[race].name
			if info.items then
				for item, itemInfo in pairs (info.items) do
					if root.itemConfig(item) then
						tempRaceTable[race].items[item] = itemInfo
					end
				end
			end
		end
	end
	return tempRaceTable
end

function getPlacementImage(objectOrientations, objectDirectory, positionOverride)
	local objectOrientation = objectOrientations[1]
	local objectImage
	if objectOrientation.imageLayers then
		objectImage = objectOrientation.imageLayers[1].image
	else
		objectImage = objectOrientation.dualImage or objectOrientation.image
	end
	local newPlacementImage
	if string.sub(objectImage, 1, 1) ~= "/" then
		newPlacementImage = objectDirectory .. objectImage
	else
		newPlacementImage = objectImage
	end

	local newPlacementImagePosition = objectOrientation.imagePosition
	if positionOverride then
		newPlacementImagePosition = positionOverride
	end
	return newPlacementImage:gsub("<frame>", 0):gsub("<color>", "default"):gsub("<key>", 1), newPlacementImagePosition
end

function getNewParameters(newItemInfo, positionOverride)
	local newParameters = {}
	if newItemInfo then
		if string.sub(newItemInfo.config.inventoryIcon, 1, 1) ~= "/" then
			newParameters.inventoryIcon = newItemInfo.directory .. newItemInfo.config.inventoryIcon
		else
			newParameters.inventoryIcon = newItemInfo.config.inventoryIcon
		end
		newParameters.placementImage, newParameters.placementImagePosition = getPlacementImage(newItemInfo.config.orientations, newItemInfo.directory, positionOverride)
		newParameters.imageConfig = getNewOrientations(newItemInfo, positionOverride)
		newParameters.imageFlipped = newItemInfo.config.sitFlipDirection
	end
	return newParameters
end

function getNewOrientations(newItemInfo, positionOverride)
	local newOrientations = newItemInfo.config.orientations
	for num, _ in pairs (newOrientations) do
		local imageLayers = newOrientations[num].imageLayers
		if imageLayers then
			for num2, _ in pairs (imageLayers) do
				local imageLayer = imageLayers[num2].image
				if string.sub(imageLayer, 1, 1) ~= "/" then
					newOrientations[num].imageLayers[num2].image = newItemInfo.directory .. imageLayer
				else
					newOrientations[num].imageLayers[num2].image = imageLayer
				end
			end
		end
		local dualImage = newOrientations[num].dualImage
		if dualImage then
			if string.sub(dualImage, 1, 1) ~= "/" then
				newOrientations[num].dualImage = newItemInfo.directory .. dualImage
			else
				newOrientations[num].dualImage = dualImage
			end
		end
		local image = newOrientations[num].image
		if image and not imageLayers then --Avali teleporter fix
			if string.sub(image, 1, 1) ~= "/" then
				newOrientations[num].image = newItemInfo.directory .. image
			else
				newOrientations[num].image = image
			end
		end
	end
	if positionOverride then
		newOrientations[1].imagePosition = positionOverride
	end
	return newOrientations
end
