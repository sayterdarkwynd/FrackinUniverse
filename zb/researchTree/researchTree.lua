require("/zb/zb_util.lua")
require("/scripts/util.lua")

-- constants
currencyTable = {}
researchTree = nil
gridTileImage = nil
gridTileSize = {}
canvasSize = nil
verified = false
canvas = nil
data = nil

-- variables
searchListRepopulationCooldown = 0
dragOffset = {x = 0, y = 0}
doubleClickCooldown = 0
idleRedrawCooldown = 0
clickTimeRemaining = 0
oldMousePos = {0,0}
lastClickPos = {0,0}
lowQuality = false
selectedTree = nil
mouseDown = false
panningTo = nil
readOnly = false
selected = nil
noCost = false

-- Basic GUI functions
function init()

	currencyTable = root.assetJson("/currencies.config")
	data = root.assetJson("/zb/researchTree/data.config")
	for _, file in ipairs(data.researchFiles) do
		local temp = root.assetJson(file)
		data = zbutil.MergeTable(data, temp)
	end

	gridTileImage = data.defaultGridTileImage
	gridTileSize = root.imageSize(gridTileImage)
	canvas = widget.bindCanvas("canvas")
	canvasSize = widget.getSize("canvas")

	verified = verifyAcronims()
	if not verified then return end

	for _, file in ipairs(data.externalScripts) do
		require(file)
	end

	-- Set middle of screen to canvases 0;0
	dragOffset.x = math.floor(canvasSize[1] * 0.5)
	dragOffset.y = math.floor(canvasSize[2] * 0.5)

	-- Research things that should be initially researched
	local researchedTable = status.statusProperty("zb_researchtree_researched", {}) or {}
	for tree, tbl in pairs(data.initiallyResearched) do
		if not researchedTable[tree] then researchedTable[tree] = "" end

		for _, acr in ipairs(tbl) do
			if not string.find(researchedTable[tree], acr..",") then
				researchedTable[tree] = researchedTable[tree]..acr..","

				if type(data.researchTree[tree][data.acronyms[tree][acr]].unlocks) == "table" then
					for _, blueprint in ipairs(data.researchTree[tree][data.acronyms[tree][acr]].unlocks) do
						player.giveBlueprint(blueprint)
					end
				elseif data.researchTree[tree][data.acronyms[tree][acr]].unlocks then
					player.giveBlueprint(data.researchTree[tree][data.acronyms[tree][acr]].unlocks)
				end

				if data.researchTree[tree][data.acronyms[tree][acr]].func then
					if _ENV[data.researchTree[tree][data.acronyms[tree][acr]].func] then
						_ENV[data.researchTree[tree][data.acronyms[tree][acr]].func](data.researchTree[tree][data.acronyms[tree][acr]].params)
					end
				end
			end
		end
	end

	-- Check if the tree was updated, and reaquire blueprints for already learned research
	for tree, dataString in pairs(researchedTable) do
		if data.versions[tree] then
			local oldVersion = ""

			local versionEndPos = string.find(dataString, data.versionSplitString)
			if versionEndPos then
				oldVersion = string.sub(dataString, 0, versionEndPos-1)
			end

			if oldVersion ~= data.versions[tree] then
				if versionEndPos then
					dataString = string.sub(dataString, versionEndPos + string.len(data.versionSplitString), string.len(dataString))
				end

				local researches = stringToAcronyms(dataString)
				for i, acr in ipairs(researches) do
					local acronymTest = data.acronyms[tree][acr]
					local unlockType

					-- Check whether there's data for the acronym, and then if it has tree data.
					if acronymTest and data.researchTree[tree][acronymTest] then
						unlockType = type(data.researchTree[tree][acronymTest].unlocks)
					end

					-- Remove acronyms that don't have a linked research
					-- Otherwise relearn relevant blueprints
					if not unlockType then
						if i == 1 then
							dataString = string.gsub(dataString, acr..",", "")
						else
							dataString = string.gsub(dataString, ","..acr..",", ",")
						end
					elseif unlockType == "table" then
						for _, blueprint in ipairs(data.researchTree[tree][data.acronyms[tree][acr]].unlocks) do
							player.giveBlueprint(blueprint)
						end
					elseif unlockType == "string" then
						player.giveBlueprint(data.researchTree[tree][data.acronyms[tree][acr]].unlocks)
					end

				end
				researchedTable[tree] = data.versions[tree]..data.versionSplitString..dataString
			end
		end
	end

	status.setStatusProperty("zb_researchtree_researched", researchedTable)

	treePickButton()
	draw()
	updateInfoPanel()
end

function update(dt)
	if not verified then return end

	if panningTo then
		if mouseDown then
			panningTo = nil
		else
			pan()
		end
	end

	if player.isAdmin() then
		widget.setVisible("cheatBox", true)
	else
		widget.setText("cheatBox", "")
		widget.setVisible("cheatBox", false)
	end

	if selected and not readOnly and researchTree[selected].state == "available" and canAfford(selected) then
		widget.setButtonEnabled("researchButton", true)
		widget.setButtonEnabled("consumptionText", true)
	else
		widget.setButtonEnabled("researchButton", false)
		widget.setButtonEnabled("consumptionText", false)
	end

	if clickTimeRemaining > 0 then
		clickTimeRemaining = clickTimeRemaining - dt
	end

	if doubleClickCooldown > 0 then
		doubleClickCooldown = doubleClickCooldown - dt
	end

	if widget.active("searchList") then
		if searchListRepopulationCooldown <= 0 then
			searchListRepopulationCooldown = data.searchListRepopulationInterval
		else
			searchListRepopulationCooldown = searchListRepopulationCooldown - dt
		end
	end

	if not lowQuality then
		if mouseDown then
			local mousePos = canvas:mousePosition()
			dragOffset.x = dragOffset.x + mousePos[1] - oldMousePos[1]
			dragOffset.y = dragOffset.y + mousePos[2] - oldMousePos[2]
			oldMousePos = mousePos

			idleRedrawCooldown = data.idleRedrawInterval
			draw()
		elseif idleRedrawCooldown <= 0 then
			idleRedrawCooldown = data.idleRedrawInterval
			draw()
		else
			idleRedrawCooldown = idleRedrawCooldown - dt
		end
	end
end

function researchButton()
	if selected and researchTree[selected].state == "available" and canAfford(selected, true) then
		researchTree[selected].state = "researched"

		if type(researchTree[selected].unlocks) == "table" then
			for _, blueprint in ipairs(researchTree[selected].unlocks) do
				player.giveBlueprint(blueprint)
			end
		elseif researchTree[selected].unlocks then
			player.giveBlueprint(researchTree[selected].unlocks)
		end

		if researchTree[selected].func and _ENV[researchTree[selected].func] then
			_ENV[researchTree[selected].func](researchTree[selected].params)
		end

		local researchedTable = status.statusProperty("zb_researchtree_researched", {}) or {}
		if not researchedTable[selectedTree] then researchedTable[selectedTree] = "" end

		for acr, research in pairs(data.acronyms[selectedTree]) do
			if research == selected then
				researchedTable[selectedTree] = researchedTable[selectedTree]..acr..","
				status.setStatusProperty("zb_researchtree_researched", researchedTable)
				break
			end
		end
	end

	buildStates()
	draw()
end

function centerButton()
	if not verified then return end
	if selected then
		panTo(researchTree[selected].position)
	else
		panTo()
	end
end

function searchButton()
	if not verified then return end
	if widget.active("searchList") then
		widget.setVisible("researchButton", true)
		widget.setVisible("consumptionText", true)
		widget.setVisible("searchList", false)
		widget.setVisible("infoList", true)

		for i = 1, 9 do
			widget.setVisible("priceItem"..i, true)
		end

		updateInfoPanel()
		widget.setButtonImages("searchButton",
		{	base = "/zb/researchTree/buttons.png:search:default",
			hover = "/zb/researchTree/buttons.png:search:hover"	})
	elseif researchTree then
		if widget.active("treeList") then treePickButton() end

		searchListRepopulationCooldown = data.searchListRepopulationInterval
		widget.setText("title", "Zoom to a research by clicking on it in the list")
		widget.setVisible("researchButton", false)
		widget.setVisible("consumptionText", false)
		widget.setVisible("searchList", true)
		widget.setVisible("infoList", false)
		populateSearchList()

		for i = 1, 9 do
			widget.setVisible("priceItem"..i, false)
		end

		widget.setButtonImages("searchButton",
		{	base = "/zb/researchTree/buttons.png:search:hover",
			hover = "/zb/researchTree/buttons.png:search:default"	})
	end
end

function treePickButton()
	if not verified then return end
	if widget.active("treeList") then
		widget.setVisible("researchButton", true)
		widget.setVisible("consumptionText", true)
		widget.setVisible("treeList", false)
		widget.setVisible("infoList", true)

		for i = 1, 9 do
			widget.setVisible("priceItem"..i, true)
		end

		local consumptionRules = getTreeConsumptionRules(selectedTree)

		if consumptionRules.currency then
			consumeText = '^red; Will consume currency'
		else
			consumeText = '^green; Will not consume currency'
		end

		if consumptionRules.items then
			consumeText = consumeText..'\n^red; Will consume items'
		else
			consumeText = consumeText..'\n^green; Will not consume items'
		end

		widget.setText("consumptionText", consumeText)

		updateInfoPanel()
		widget.setButtonImages("treePickButton",
		{	base = "/zb/researchTree/buttons.png:treePick:default",
			hover = "/zb/researchTree/buttons.png:treePick:hover"	})
	else
		if widget.active("searchList") then searchButton() end

		searchListRepopulationCooldown = data.searchListRepopulationInterval
		widget.setText("title", "Select a research tree")
		widget.setVisible("researchButton", false)
		widget.setVisible("consumptionText", false)
		widget.setVisible("treeList", true)
		widget.setVisible("infoList", false)
		populateTreeList()

		for i = 1, 9 do
			widget.setVisible("priceItem"..i, false)
		end

		widget.setButtonImages("treePickButton",
		{	base = "/zb/researchTree/buttons.png:treePick:hover",
			hover = "/zb/researchTree/buttons.png:treePick:default"	})
	end
end

function closeButton()
	 pane.dismiss()
end

function updateInfoPanel()
	if not widget.active("searchList") and not widget.active("treeList") then
		widget.clearListItems("infoList.unlocks")
		widget.setVisible("infoList.unlocksLabel", false)
		widget.setPosition("infoList.unlocks", {0,0})

		for i = 1, 9 do
			widget.setItemSlotItem("priceItem"..i, nil)
		end

		if selected then
			if data.strings.research[selected] then
				widget.setText("title", data.strings.research[selected][1])
				widget.setText("infoList.text", data.strings.research[selected][2])
			else
				widget.setText("title", selected)
				widget.setText("infoList.text", "ERROR - Missing text data for selected research")
			end

			if researchTree[selected].price then
				for i, tbl in ipairs(researchTree[selected].price) do
					widget.setItemSlotItem("priceItem"..i, {name = tbl[1], count = tbl[2]})
					if i >= 9 then break end
				end
			end

			if researchTree[selected].unlocks and not researchTree[selected].hideUnlocks then
				if type(researchTree[selected].unlocks) == "table" then
					widget.setVisible("infoList.unlocksLabel", true)
					local listItem = ""
					for i, item in ipairs(researchTree[selected].unlocks) do
						if (i-1)%9 == 0 then
							local pos = widget.getPosition("infoList.unlocks")
							widget.setPosition("infoList.unlocks", {pos[1], pos[2]-18})

							listItem = "infoList.unlocks."..widget.addListItem("infoList.unlocks")
						end
						widget.setItemSlotItem(listItem..".item"..(i-1)%9, {name = item})
						widget.setVisible(listItem..".item"..(i-1)%9, true)
					end
				else
					local pos = widget.getPosition("infoList.unlocks")
					widget.setPosition("infoList.unlocks", {pos[1], pos[2]-18})

					widget.setVisible("infoList.unlocksLabel", true)
					local listItem = "infoList.unlocks."..widget.addListItem("infoList.unlocks")
					widget.setItemSlotItem(listItem..".item0", {name = researchTree[selected].unlocks})
					widget.setVisible(listItem..".item0", true)
				end
			end
		else
			widget.setText("title", data.strings.info[1])
			widget.setText("infoList.text", data.strings.info[2])
		end
	end
end

function populateSearchList()
	widget.clearListItems("searchList.list")
	local listTable = {researched = {}, available = {}, expensive = {}, unavailable = {}}
	local listItem

	if researchTree then
		for research, tbl in pairs(researchTree) do
			if not tbl.state or tbl.state == "unavailable" then
				table.insert(listTable.unavailable, research)

			elseif tbl.state == "researched" then
				table.insert(listTable.researched, research)

			elseif tbl.state == "available" then
				if canAfford(research) then
					table.insert(listTable.available, research)
				else
					table.insert(listTable.expensive, research)
				end
			end
		end

		for _, research in ipairs(listTable.available) do
			listItem = "searchList.list."..widget.addListItem("searchList.list")
			widget.setData(listItem, research)

			if data.strings.research[research] then
				widget.setText(listItem..".title", data.strings.research[research][1])
			else
				widget.setText(listItem..".title", research)
			end

			widget.setImage(listItem..".icon", researchTree[research].icon)
			widget.setFontColor(listItem..".title", "#22FFFF")
		end

		for _, research in ipairs(listTable.expensive) do
			listItem = "searchList.list."..widget.addListItem("searchList.list")
			widget.setData(listItem, research)

			if data.strings.research[research] then
				widget.setText(listItem..".title", data.strings.research[research][1])
			else
				widget.setText(listItem..".title", research)
			end

			widget.setImage(listItem..".icon", researchTree[research].icon)
			widget.setFontColor(listItem..".title", "#FFFF22")
		end

		for _, research in ipairs(listTable.unavailable) do
			listItem = "searchList.list."..widget.addListItem("searchList.list")
			widget.setData(listItem, research)

			if data.strings.research[research] then
				widget.setText(listItem..".title", data.strings.research[research][1])
			else
				widget.setText(listItem..".title", research)
			end

			widget.setImage(listItem..".icon", researchTree[research].icon)
			widget.setFontColor(listItem..".title", "#FF2222")
		end

		for _, research in ipairs(listTable.researched) do
			listItem = "searchList.list."..widget.addListItem("searchList.list")
			widget.setData(listItem, research)

			if data.strings.research[research] then
				widget.setText(listItem..".title", data.strings.research[research][1])
			else
				widget.setText(listItem..".title", research)
			end

			widget.setImage(listItem..".icon", researchTree[research].icon)
			widget.setFontColor(listItem..".title", "#22FF22")
		end
	end
end

function populateTreeList()
	widget.clearListItems("treeList.list")

	local toSort = {}
	for tree, _ in pairs(data.researchTree) do
		local isAvailable = true

		if data.treeUnlocks[tree] then
			if data.treeUnlocks[tree].quests then
				for _, questId in ipairs(data.treeUnlocks[tree].quests) do
					if not player.hasCompletedQuest(questId) then
						isAvailable = false
						break
					end
				end
			end

			if isAvailable and data.treeUnlocks[tree].research then
				for requiredAnotherTree, acronyms in pairs(data.treeUnlocks[tree].research) do
					if not isResearched(requiredAnotherTree, acronyms) then
						isAvailable = false
						break
					end
				end
			end
		end

		if isAvailable then
			table.insert(toSort, {tree = tree, name = data.strings.trees[tree] or tree})
		end
	end

	if (#toSort == 0) then
		local listItem = "treeList.list."..widget.addListItem("treeList.list")
		widget.setText(listItem..".title", '^red;No Trees Available')
		widget.setButtonEnabled(listItem..".title", false)
	else
		table.sort(toSort, function(a, b) return a.name:upper() < b.name:upper() end)

		for _, d in ipairs(toSort) do
			local listItem = "treeList.list."..widget.addListItem("treeList.list")
			widget.setData(listItem, d.tree)
			widget.setText(listItem..".title", d.name)

			if (data.treeIcons[d.tree]) then
				widget.setImage(listItem..".icon", data.treeIcons[d.tree])
			end
		end
	end
end

function researchSelected()
	local wdata = widget.getListSelected("searchList.list")
	if wdata then
		wdata = widget.getData("searchList.list."..wdata)
		selected = wdata
		panTo(researchTree[wdata].position)
	end
end

function treeSelected()
	local wdata = widget.getListSelected("treeList.list")
	if wdata then
		wdata = widget.getData("treeList.list."..wdata)
		if wdata then
			gridTileImage = data.cutsomGridTileImages[wdata] or data.defaultGridTileImage
			gridTileSize = root.imageSize(gridTileImage)
			buildStates(wdata)
			treePickButton()
			panTo()
		end
	end
end

function qualityButton()
	if lowQuality then
		lowQuality = false
	else
		lowQuality = true
	end
end

function uninit() end

-- Canvas functions
function draw()
	canvas:clear()

	-- Draw background
	local gridOffset = {dragOffset.x % gridTileSize[1], dragOffset.y % gridTileSize[2]}
	canvas:drawTiledImage(gridTileImage, gridOffset, {0, 0, canvasSize[1] + gridTileSize[1], canvasSize[2] + gridTileSize[2]})

	-- Draw "READ ONLY"
	if readOnly then
		canvas:drawText("READ ONLY!", {position = {57, canvasSize[2]-2}}, 7, "#FF5E66F0")
	end

	-- Draw research nodes
	if researchTree then
		local startPoint = {0,0}
		local endPoint = {0,0}

		-- draw tree lines
		for _, tbl in pairs(researchTree) do
			if tbl.state ~= "hidden" then
				if tbl.children and #tbl.children > 0 then
					startPoint[1] = tbl.position[1] + dragOffset.x
					startPoint[2] = tbl.position[2] + dragOffset.y

					local color = "#000000"

					for _, child in ipairs(tbl.children) do
						endPoint[1] = researchTree[child].position[1] + dragOffset.x
						endPoint[2] = researchTree[child].position[2] + dragOffset.y

						if whithinBounds(startPoint, endPoint) then
							local state = researchTree[child].state

							if state ~= "hidden" then
								if not state or state == "unavailable" then
									color = "#FF0000"
								elseif state == "researched" then
									color = "#00FF00"
								elseif state == "available" then
									if canAfford(child) then
										color = "#00FFFF"
									else
										color = "#df7126"
									end
								end

								canvas:drawLine(startPoint, endPoint, color, 2)
							end
						end
					end
				end
			end
		end

		-- draw icons
		for research, tbl in pairs(researchTree) do
			startPoint[1] = tbl.position[1] + dragOffset.x - (data.iconSizes * 0.5)
			startPoint[2] = tbl.position[2] + dragOffset.y - (data.iconSizes * 0.5)
			endPoint[1] = startPoint[1] + data.iconSizes
			endPoint[2] = startPoint[2] + data.iconSizes

			if whithinBounds(startPoint, endPoint) then
				if tbl.state ~= "hidden" then
					local color = "#000000"
					if not tbl.state or tbl.state == "unavailable" then
						color = "#FF5555"
					elseif tbl.state == "researched" then
						color = "#37db42"
					elseif tbl.state == "available" then
						if canAfford(research) then
							color = "#55FFFF"
						else
							color = "#dfb326"
						end
					end

					if research == selected then
						canvas:drawImage("/zb/researchTree/iconBackground.png:selected", {startPoint[1]-2, startPoint[2]-2}, 1, color, false)
					else
						canvas:drawImage("/zb/researchTree/iconBackground.png:default", {startPoint[1]-2, startPoint[2]-2}, 1, color, false)
					end

					if tbl.state == "researched" then
						canvas:drawImage(tbl.icon, startPoint, 1, "#FFFFFF", false)
					else
						canvas:drawImage(tbl.icon, startPoint, 1, color, false)
					end
				end
			end
		end
	else
		canvas:drawText("NO RESEARCH TREE SELECTED", {position = {canvasSize[1]*0.5, canvasSize[2]*0.5}, horizontalAnchor = "mid", verticalAnchor = "mid"}, 20, "#FF5E66F0")
	end

	-- Draw currencies
	local mousePosition = canvas:mousePosition()
	for i, tbl in ipairs(data.currencies) do
		if not tbl[5] or player.currency(tbl[1]) > 0 then
			startPoint = {3, canvasSize[2] - i * 11}

			canvas:drawImage(tbl[4], startPoint, 1, "#FFFFFF", false)

			if mousePosition[1] >= startPoint[1]-1 and mousePosition[1] <= startPoint[1] + 8
			and mousePosition[2] >= startPoint[2]-1 and mousePosition[2] <= startPoint[2] + 8 then
				if tbl[1] == "essence" then
					canvas:drawText("Essence", {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				elseif tbl[1] == "money" then
					canvas:drawText("Pixels", {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				else
					canvas:drawText(data.strings.currencies[tbl[1]] or tbl[1], {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				end
			else
				canvas:drawText(player.currency(tbl[1]), {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
			end
		end
	end
end

function pan()
	if not panningTo then return end

	if lowQuality then
		dragOffset.x = math.floor(canvasSize[1] * 0.5) - panningTo[1]
		dragOffset.y = math.floor(canvasSize[2] * 0.5) - panningTo[2]
	else
		dragOffset.x = dragOffset.x + ((math.floor(canvasSize[1] * 0.5) - panningTo[1] - dragOffset.x) * 0.06)
		dragOffset.y = dragOffset.y + ((math.floor(canvasSize[2] * 0.5) - panningTo[2] - dragOffset.y) * 0.06)
	end

	draw()
end

function panTo(pos)
	mouseDown = false
	if pos then panningTo = pos
	else panningTo = {0,0} end
end

function whithinBounds(startPoint, endPoint)
	local xPass = false
	local yPass = false

	if startPoint[1] > 0 and startPoint[1] < canvasSize[1] then
		xPass = true
	elseif endPoint[1] > 0 and endPoint[1] < canvasSize[1] then
		xPass = true
	elseif startPoint[1] == 0 or endPoint[1] == canvasSize[1] then
		xPass = true
	elseif endPoint[1] == 0 or startPoint[1] == canvasSize[1] then
		xPass = true
	end

	if startPoint[2] > 0 and startPoint[2] < canvasSize[2] then
		yPass = true
	elseif endPoint[2] > 0 and endPoint[2] < canvasSize[2] then
		yPass = true
	elseif startPoint[2] == 0 or endPoint[2] == canvasSize[2] then
		yPass = true
	elseif endPoint[2] == 0 or startPoint[2] == canvasSize[2] then
		yPass = true
	end

	if xPass and yPass then
		return true
	end

	if yPass then
		if startPoint[1] < 0 and endPoint[1] > canvasSize[1] then
			return true
		elseif endPoint[1] < 0 and startPoint[1] > canvasSize[1] then
			return true
		end
	end

	if xPass then
		if startPoint[2] < 0 and endPoint[2] > canvasSize[2] then
			return true
		elseif endPoint[2] < 0 and startPoint[2] > canvasSize[2] then
			return true
		end
	end

	if startPoint[1] < 0 and startPoint[2] < 0 then
		if endPoint[1] > 0 and endPoint[2] > 0 then
			return true
		end
	elseif endPoint[1] < 0 and endPoint[2] < 0 then
		if startPoint[1] > 0 and startPoint[2] > 0 then
			return true
		end
	end

	if startPoint[1] < 0 and startPoint[2] > canvasSize[2] then
		if endPoint[1] > 0 and endPoint[2] < canvasSize[2] then
			return true
		end
	elseif endPoint[1] < 0 and endPoint[2] > canvasSize[2] then
		if startPoint[1] > 0 and startPoint[2] < canvasSize[2] then
			return true
		end
	end

	return false
end

function canvasClickEvent(position, button, isButtonDown)
	if not verified then return end
	if button == 0 then
		mouseDown = isButtonDown
		oldMousePos = position

		if isButtonDown then
			clickTimeRemaining = data.clickTime
		elseif clickTimeRemaining > 0 then
			clickTimeRemaining = 0

			local isDouble = doubleClickCooldown > 0 and math.abs(position[1] - lastClickPos[1]) <= 1 and math.abs(position[2] - lastClickPos[2])
			leftClick(position, isDouble)

			lastClickPos = {position[1], position[2]};
		elseif lowQuality then
			draw()
		end
	end
end

function leftClick(clickPos, isDouble)
	local clicked = nil

	if researchTree then
		for research, tbl in pairs(researchTree) do
			local xRange = {tbl.position[1] + dragOffset.x - (data.iconSizes * 0.5) - 1, tbl.position[1] + dragOffset.x + (data.iconSizes * 0.5) + 1}
			if clickPos[1] > xRange[1] and clickPos[1] < xRange[2] then

				local yRange = {tbl.position[2] + dragOffset.y - (data.iconSizes * 0.5) - 1, tbl.position[2] + dragOffset.y + (data.iconSizes * 0.5) + 1}
				if clickPos[2] > yRange[1] and clickPos[2] < yRange[2] then
					if tbl.state ~= "hidden" then
						clicked = research
					end
					break
				end
			end
		end
	end

	if isDouble then
		if selected == clicked then
			researchButton()
		else
			selected = clicked
			doubleClickCooldown = data.doubleClickTime
		end
	else
		if clicked then
			doubleClickCooldown = data.doubleClickTime
		end
		selected = clicked
	end

	updateInfoPanel()
	draw()
end


-- Research tree functions
function verifyAcronims()
	local missing = ""

	for t, tbl in pairs(data.researchTree) do
		local tree = t
		for res1, _ in pairs(tbl) do
			local found = false
			for _, res2 in pairs(data.acronyms[tree]) do
				if res1 == res2 then
					found = true
					break
				end
			end

			if not found then
				missing = missing.."("..tree..") "..res1.."\n"
			end
		end
	end

	if missing == "" then
		return true
	else
		widget.setVisible("researchButton", false)
		widget.setVisible("consumptionText", false)
		widget.setVisible("treePickButton", false)
		widget.setVisible("centerButton", false)
		widget.setVisible("searchButton", false)
		widget.setText("title", "^red;ERROR:^reset; Researches missing acronyms")
		widget.setText("infoList.text", missing)
		canvas:drawLine({0, canvasSize[2]*0.5}, {canvasSize[1], canvasSize[2]*0.5}, "#16232BF0", canvasSize[2]*2)
		canvas:drawText("ERROR\nMISSING ACRONYMS", {position = {canvasSize[1]*0.5, canvasSize[2]*0.5}, horizontalAnchor = "mid", verticalAnchor = "mid"}, 20, "#FF5E66F0")

		return false
	end
end

function stringToAcronyms(dataString)
	local splitString = {}
	local _, count = string.gsub(dataString, ",", "")
	for _ = 1, count do
		local splitpos = string.find(dataString, ",")
		local insertingString = string.sub(dataString, 1, splitpos)
		dataString = string.gsub(dataString, insertingString, "")

		insertingString = string.gsub(insertingString, ",", "")
		table.insert(splitString, insertingString)
	end

	return splitString
end

function buildStates(tree)
	selected = nil
	if tree then
		selectedTree = tree
	elseif not selectedTree then
		return
	end

	researchTree = copy(data.researchTree[selectedTree])

	local researchedTable = status.statusProperty("zb_researchtree_researched", {}) or {}
	local dataString = researchedTable[selectedTree] or ""

	local versionEndPos = string.find(dataString, data.versionSplitString)
	if versionEndPos then
		dataString = string.sub(dataString, versionEndPos + string.len(data.versionSplitString), string.len(dataString))
	end

	local splitString = stringToAcronyms(dataString)

	for _, acr in ipairs(splitString) do
		if data.acronyms[selectedTree][acr] and researchTree[data.acronyms[selectedTree][acr]] then
			researchTree[data.acronyms[selectedTree][acr]].state = "researched"

			if researchTree[data.acronyms[selectedTree][acr]].children then
				for _, child in ipairs(researchTree[data.acronyms[selectedTree][acr]].children) do
					if researchTree[child].state ~= "researched" then
						local isAvailable = true

						for research, tbl in pairs(researchTree) do
							if research ~= data.acronyms[selectedTree][acr] and tbl.children then
								for _, child2 in ipairs(tbl.children) do
									if child2 == child and tbl.state ~= "researched" then
										isAvailable = false
										break
									end
								end
							end

							if not isAvailable then break end
						end

						if isAvailable then
							researchTree[child].state = "available"
						end
					end
				end
			end
		end
	end

	if data.hiddenResearch[selectedTree] then
		for _, acr in ipairs(data.hiddenResearch[selectedTree]) do
			if researchTree[data.acronyms[selectedTree][acr]] and not researchTree[data.acronyms[selectedTree][acr]].state then
				hideResearchBranch(data.acronyms[selectedTree][acr])
			end
		end
	end
end

function hideResearchBranch(research)
	if not researchTree[research].state then
		researchTree[research].state = "hidden"

		if researchTree[research].children then
			for _, child in ipairs(researchTree[research].children) do
				hideResearchBranch(child)
			end
		end
	end
end

function canAfford(research, consume)
	if noCost then return true end

	if researchTree[research].price then
		for _, tbl in ipairs(researchTree[research].price) do
			if currencyTable[tbl[1]] then
				if player.currency(tbl[1]) < tbl[2] then
					return false
				end
			else
				if player.hasCountOfItem(tbl[1]) < tbl[2] then
					return false
				end
			end
		end
	end

	-- Running the loops again so it consumes stuff AFTER checking that the player has everything
	if consume then
		local consumptionRules = getTreeConsumptionRules(selectedTree)
		for _, tbl in ipairs(researchTree[research].price) do
			if currencyTable[tbl[1]] then
				if consumptionRules.currency then
					player.consumeCurrency(tbl[1], tbl[2])
				end
			else
				if consumptionRules.items then
					player.consumeItem({name = tbl[1], count = tbl[2]}, true)
				end
			end
		end
	end

	return true
end

function isResearched(tree, acronym)
	local researched = status.statusProperty("zb_researchtree_researched", {}) or {}

	if researched and researched[tree] then
		if type(acronym) == 'string' then
			if string.match(researched[tree], acronym..',') then
				return true
			end
		elseif type(acronym) == 'table' then
			for _, acr in ipairs(acronym) do
				if not string.match(researched[tree], acr..',') then
					return false
				end
			end
			return true
		end
	end

	return false
end

function getTreeConsumptionRules(tree)
	if not data.customConsumptionRules[selectedTree] then
		return {currency = true, items = true}
	end

	return {
		currency = data.customConsumptionRules[selectedTree].currency == nil or data.customConsumptionRules[selectedTree].currency == true,
		items = data.customConsumptionRules[selectedTree].items == nil or data.customConsumptionRules[selectedTree].items == true
	}
end

--		Cheat codes
-- nocosttoogreat					- Toggle free researches
-- iamabeaconofknowledge			- Research everything
-- forgottenmemories				- Reset researches
-- revealourselves					- Unhides all researches
-- nostringsonme					- Disables "read only" mode
-- kotlgiffmana	[acronym string]	- Research the specified acronyms in the current research tree
-- bankrupt							- Resets all currencies displayed on the side to 0

cheats = {
	nocosttoogreat = function()
		noCost = not noCost
	end,

	iamabeaconofknowledge = function()
		local researchTable = {}
		for tree, tbl in pairs(data.acronyms) do
			if not researchTable[tree] then researchTable[tree] = "" end

			for acr, res in pairs(tbl) do
				researchTable[tree] = researchTable[tree]..acr..","
				if data.researchTree[tree] and data.researchTree[tree][res] then
					if type(data.researchTree[tree][res].unlocks) == "table" then
						for _, blueprint in ipairs(data.researchTree[tree][res].unlocks) do
							player.giveBlueprint(blueprint)
						end
					elseif data.researchTree[tree][res].unlocks then
						player.giveBlueprint(data.researchTree[tree][res].unlocks)
					end

					if data.researchTree[tree][res].func then
						if _ENV[data.researchTree[tree][res].func] then
							_ENV[data.researchTree[tree][res].func](data.researchTree[tree][res].params)
						end
					end
				end
			end
		end

		status.setStatusProperty("zb_researchtree_researched", researchTable)
		buildStates()
	end,

	forgottenmemories = function()
		status.setStatusProperty("zb_researchtree_researched", nil)
		pane.dismiss()
		player.interact("ScriptPane", "/zb/researchTree/researchTree.config")
	end,

	revealourselves = function()
		for _, tbl in pairs(researchTree) do
			if tbl.state == "hidden" then
				tbl.state = nil
			end
		end
	end,

	nostringsonme = function()
		readOnly = false
		widget.setText("researchButton", "Research")
		if selected and researchTree[selected].state == "available" then
			widget.setButtonEnabled("researchButton", true)
		else
			widget.setButtonEnabled("researchButton", false)
		end
	end,

	kotlgiffmana = function(text)
		if text and selectedTree then
			text = string.gsub(text, "kotlgiffmana ", "")
			if data.acronyms[selectedTree][text] then
				local researchedTable = status.statusProperty("zb_researchtree_researched", {}) or {}
				if not researchedTable[selectedTree] then researchedTable[selectedTree] = "" end

				if data.researchTree[selectedTree] then
					if type(data.researchTree[selectedTree][data.acronyms[selectedTree][text]].unlocks) == "table" then
						for _, blueprint in ipairs(data.researchTree[selectedTree][data.acronyms[selectedTree][text]].unlocks) do
							player.giveBlueprint(blueprint)
						end
					elseif data.researchTree[selectedTree][data.acronyms[selectedTree][text]].unlocks then
						player.giveBlueprint(data.researchTree[selectedTree][data.acronyms[selectedTree][text]].unlocks)
					end

					if data.researchTree[selectedTree][data.acronyms[selectedTree][text]].func then
						if _ENV[data.researchTree[selectedTree][data.acronyms[selectedTree][text]].func] then
							_ENV[data.researchTree[selectedTree][data.acronyms[selectedTree][text]].func](data.researchTree[selectedTree][data.acronyms[selectedTree][text]].params)
						end
					end
				end

				researchedTable[selectedTree] = researchedTable[selectedTree]..text..","
				status.setStatusProperty("zb_researchtree_researched", researchedTable)
				buildStates()
			end
		end
	end,

	bankrupt = function()
		for _, tbl in ipairs(data.currencies) do
			player.consumeCurrency(tbl[1], player.currency(tbl[1]))
		end
	end,
}

function cheat(wd)
	if player.isAdmin() then
		local text = widget.getText(wd)

		if string.len(text or "") > 0 then
			if cheats[text] then
				cheats[text]()
				selected = nil
			else
				local space = string.find(text, " ")
				if space then
					local word = string.sub(text, 1, space-1)
					if cheats[word] then
						cheats[word](text)
						selected = nil
					end
				end
			end
		end

		draw()
		widget.setText(wd, "")
	end
end
