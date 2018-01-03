

--		TO DO:
-- price display

-- constants
searchListRepopulationInterval = 0
idleRedrawInterval = 0
doubleClickTime = 0
defaultCurrency = ""
gridTileSize = 0
canvasSize = nil
verified = true
iconSizes = 0
clickTime = 0
canvas = nil

-- variables
searchListRepopulationCooldown = 0
dragOffset = {x = 0, y = 0}
doubleClickCooldown = 0
idleRedrawCooldown = 0
clickTimeRemaining = 0
oldMousePos = {0,0}
mouseDown = false
panningTo = nil
readOnly = false
selected = nil
noCost = false

-- tables
hiddenResearch = {}
researchTree = {}
textData = {}
acronyms = {}


-- Basic GUI functions
function init()
	local data = root.assetJson("/interface/scripted/fu_researchtreegui/researchData.config")
	
	searchListRepopulationInterval = data.searchListRepopulationInterval
	idleRedrawInterval = data.idleRedrawInterval
	doubleClickTime = data.doubleClickTime
	defaultCurrency = data.defaultCurrency
	hiddenResearch = data.hiddenResearch
	gridTileSize = data.gridTileSize
	currencies = data.currencies
	iconSizes = data.iconSizes
	clickTime = data.clickTime
	acronyms = data.acronyms
	textData = data.strings
	
	verified = verifyAcronims()
	if not verified then
		widget.setVisible("researchButton", false)
		widget.setVisible("centerButton", false)
		widget.setVisible("searchButton", false)
		return
	end
	
	canvas = widget.bindCanvas("canvas")
	canvasSize = widget.getSize("canvas")
	
	-- Set middle of screen to canvases 0;0
	dragOffset.x = math.floor(canvasSize[1] * 0.5)
	dragOffset.y = math.floor(canvasSize[2] * 0.5)
	
	-- Research things that should be initially researched
	local researched = status.statusProperty("FUresearch", "")
	for _, research in ipairs(data.initiallyResearched) do
		for acr, res in pairs(acronyms) do
			if res == research and not string.find(researched, acr..",") then
				local str = researched..acr..","
				status.setStatusProperty("FUresearch", str)
				break
			end
		end
	end
	
	buildStates()
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
	
	if selected then
		if canAfford(selected) then
			if readOnly or researchTree[selected].state == "researched" then
				widget.setButtonEnabled("researchButton", false)
			else
				widget.setButtonEnabled("researchButton", true)
			end
		else
			widget.setButtonEnabled("researchButton", false)
		end
	else
		widget.setButtonEnabled("researchButton", false)
	end
	
	if clickTimeRemaining > 0 then
		clickTimeRemaining = clickTimeRemaining - dt
	end
	
	if doubleClickCooldown > 0 then
		doubleClickCooldown = doubleClickCooldown - dt
	end
	
	if widget.active("searchList") then
		if searchListRepopulationCooldown <= 0 then
			searchListRepopulationCooldown = searchListRepopulationInterval
			populateSearchList()
		else
			searchListRepopulationCooldown = searchListRepopulationCooldown - dt
		end
	end
	
	if mouseDown then
		local mousePos = canvas:mousePosition()
		dragOffset.x = dragOffset.x + mousePos[1] - oldMousePos[1]
		dragOffset.y = dragOffset.y + mousePos[2] - oldMousePos[2]
		oldMousePos = mousePos
		
		idleRedrawCooldown = idleRedrawInterval
		draw()
	else
		if idleRedrawCooldown <= 0 then
			idleRedrawCooldown = idleRedrawInterval
			draw()
		else
			idleRedrawCooldown = idleRedrawCooldown - dt
		end
	end
end

function researchButton()
	if selected and researchTree[selected].state == "available" then
		if canAfford(selected, true) then
			researchTree[selected].state = "researched"
			
			if researchTree[selected].blueprint then
				player.giveBlueprint(researchTree[selected].blueprint)
			end
			
			for acr, research in pairs(acronyms) do
				if research == selected then
					local str = status.statusProperty("FUresearch", "")..acr..","
					status.setStatusProperty("FUresearch", str)
					break
				end
			end
		end
	end
	
	buildStates()
	draw()
end

function centerButton()
	panTo() end

function searchButton()
	if widget.active("searchList") then
		widget.setVisible("researchButton", true)
		widget.setVisible("searchList", false)
		widget.setVisible("text", true)
		
		for i = 1, 9 do
			widget.setVisible("priceItem"..i, true)
		end
		
		updateInfoPanel()
		widget.setButtonImages("searchButton",
		{	base = "/interface/scripted/fu_researchtreegui/buttons.png:search:default",
			hover = "/interface/scripted/fu_researchtreegui/buttons.png:search:hover"	})
	else
		searchListRepopulationCooldown = searchListRepopulationInterval
		widget.setText("title", "Zoom to a research by clicking on it in the list")
		widget.setVisible("researchButton", false)
		widget.setVisible("searchList", true)
		widget.setVisible("text", false)
		populateSearchList()
		
		for i = 1, 9 do
			widget.setVisible("priceItem"..i, false)
		end
		
		widget.setButtonImages("searchButton",
		{	base = "/interface/scripted/fu_researchtreegui/buttons.png:search:hover",
			hover = "/interface/scripted/fu_researchtreegui/buttons.png:search:default"	})
	end
end

function closeButton()
	 pane.dismiss()
end

function updateInfoPanel()
	if not widget.active("searchList") then
		for i = 1, 9 do
			widget.setItemSlotItem("priceItem"..i, nil)
		end
		
		if selected then
			if textData[selected] then
				widget.setText("title", textData[selected][1])
				widget.setText("text", textData[selected][2])
			else
				widget.setText("title", selected)
				widget.setText("text", "ERROR - Missing text data for selected research")
			end
			
			if researchTree[selected].price then
				if type(researchTree[selected].price) == "table" then
					for i = 1, 9 do
						local price = researchTree[selected].price[i]
						if price then
							local isCurrency = false
							for _, tbl in ipairs(currencies) do
								if price[1] == tbl[1] then
									widget.setItemSlotItem("priceItem"..i, {name = tbl[3], count = price[2]})
									isCurrency = true
									break
								end
							end
							
							if not isCurrency then
								widget.setItemSlotItem("priceItem"..i, {name = price[1], count = price[2]})
							end
						end
					end
				else
					for _, tbl in ipairs(currencies) do
						if defaultCurrency == tbl[1] then
							widget.setItemSlotItem("priceItem1", {name = tbl[3], count = researchTree[selected].price})
							break
						end
					end
				end
			end
		else
			widget.setText("title", textData.default[1])
			widget.setText("text", textData.default[2])
		end
	end
end

function populateSearchList()
	widget.clearListItems("searchList.list")
	local listTable = {researched = {}, available = {}, expensive = {}, unavailable = {}}
	local listItem = ""
	
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
	
	for _, research in ipairs(listTable.researched) do
		listItem = "searchList.list."..widget.addListItem("searchList.list")
		widget.setData(listItem, research)
		
		if textData[research] then
			widget.setText(listItem..".title", textData[research][1])
		else
			widget.setText(listItem..".title", research)
		end
		
		widget.setImage(listItem..".icon", researchTree[research].icon)
		widget.setFontColor(listItem..".title", "#22FF22")
	end
	
	for _, research in ipairs(listTable.available) do
		listItem = "searchList.list."..widget.addListItem("searchList.list")
		widget.setData(listItem, research)
		
		if textData[research] then
			widget.setText(listItem..".title", textData[research][1])
		else
			widget.setText(listItem..".title", research)
		end
		
		widget.setImage(listItem..".icon", researchTree[research].icon)
		widget.setFontColor(listItem..".title", "#22FFFF")
	end
	
	for _, research in ipairs(listTable.expensive) do
		listItem = "searchList.list."..widget.addListItem("searchList.list")
		widget.setData(listItem, research)
		
		if textData[research] then
			widget.setText(listItem..".title", textData[research][1])
		else
			widget.setText(listItem..".title", research)
		end
		
		widget.setImage(listItem..".icon", researchTree[research].icon)
		widget.setFontColor(listItem..".title", "#FFFF22")
	end
	
	for _, research in ipairs(listTable.unavailable) do
		listItem = "searchList.list."..widget.addListItem("searchList.list")
		widget.setData(listItem, research)
		
		if textData[research] then
			widget.setText(listItem..".title", textData[research][1])
		else
			widget.setText(listItem..".title", research)
		end
		
		widget.setImage(listItem..".icon", researchTree[research].icon)
		widget.setFontColor(listItem..".title", "#FF2222")
	end
end

function researchSelected()
	local data = widget.getListSelected("searchList.list")
	if data then
		data = widget.getData("searchList.list."..data)
		panTo(researchTree[data].position)
	end
end

function uninit() end

-- Canvas functions
function draw()
	canvas:clear()
	
	-- Draw background
	local gridOffset = {dragOffset.x % gridTileSize, dragOffset.y % gridTileSize}
	canvas:drawTiledImage("/interface/scripted/fu_researchtreegui/gridTile.png", gridOffset, {0, 0, canvasSize[1] + 19, canvasSize[2] + 19})
	
	-- Draw "READ ONLY"
	if readOnly then
		canvas:drawText("READ ONLY!", {position = {9, canvasSize[2]-5}}, 7, "#FF0000")
	end
	
	local startPoint = {0,0}
	local endPoint = {0,0}
	
	-- draw tree lines
	for research, tbl in pairs(researchTree) do
		if tbl.state ~= "hidden" then
			if tbl.children and #tbl.children > 0 then
				startPoint[1] = tbl.position[1] + dragOffset.x
				startPoint[2] = tbl.position[2] + dragOffset.y
				
				local color = "#000000"
				local state = ""
				
				for _, child in ipairs(tbl.children) do
					endPoint[1] = researchTree[child].position[1] + dragOffset.x
					endPoint[2] = researchTree[child].position[2] + dragOffset.y
					
					if whithinBounds(startPoint, endPoint) then
						state = researchTree[child].state
						
						if state ~= "hidden" then
							if not state or state == "unavailable" then
								color = "#FF0000"
							elseif state == "researched" then
								color = "#00FF00"
							elseif state == "available" then
								if canAfford(child) then
									color = "#00FFFF"
								else
									color = "#FFFF00"
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
		startPoint[1] = tbl.position[1] + dragOffset.x - (iconSizes * 0.5)
		startPoint[2] = tbl.position[2] + dragOffset.y - (iconSizes * 0.5)
		endPoint[1] = startPoint[1] + iconSizes
		endPoint[2] = startPoint[2] + iconSizes
		
		if whithinBounds(startPoint, endPoint) then
			if tbl.state ~= "hidden" then
				local color = "#000000"
				if not tbl.state or tbl.state == "unavailable" then
					color = "#FF5555"
				elseif tbl.state == "researched" then
					color = "#55FF55"
				elseif tbl.state == "available" then
					if canAfford(research) then
						color = "#55FFFF"
					else
						color = "#FFFF55"
					end
				end
			
				if research == selected then
					canvas:drawImage("/interface/scripted/fu_researchtreegui/iconBackground.png:selected", {startPoint[1]-2, startPoint[2]-2}, 1, color, false)
				else
					canvas:drawImage("/interface/scripted/fu_researchtreegui/iconBackground.png:default", {startPoint[1]-2, startPoint[2]-2}, 1, color, false)
				end
				
				if tbl.state == "researched" then
					canvas:drawImage(tbl.icon, startPoint, 1, "#FFFFFF", false)
				else
					canvas:drawImage(tbl.icon, startPoint, 1, color, false)
				end
			end
		end
	end
	
	-- draw currencies
	local mousePosition = canvas:mousePosition()
	for i, tbl in ipairs(currencies) do
		if tbl[1] == "essence" or tbl[1] == "pixels" or tbl[1] == defaultCurrency or (player.currency(tbl[1]) > 0 or player.blueprintKnown(tbl[1])) then
			startPoint = {3, canvasSize[2] - ((i - 1) * (8 + 3) + 8 + 16 + 5)}
			
			canvas:drawImage(tbl[4], startPoint, 1, "#FFFFFF", false)
			
			if mousePosition[1] > startPoint[1]-1 and mousePosition[1] <= startPoint[1] + 8
			and mousePosition[2] > startPoint[2]-1 and mousePosition[2] <= startPoint[2] + 8 then
				if tbl[1] == "essence" then
					canvas:drawText("Essence", {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				elseif tbl[1] == "pixels" then
					canvas:drawText("Pixels", {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				else
					canvas:drawText(textData[tbl[1]] or tbl[1], {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
				end
			else
				canvas:drawText(player.currency(tbl[1]), {position = {startPoint[1] + 8 + 3, startPoint[2]}, verticalAnchor = "bottom"}, 7, tbl[2])
			end
		end
	end
end

function pan()
	if not panningTo then return end
	
	dragOffset.x = dragOffset.x + ((math.floor(canvasSize[1] * 0.5) - panningTo[1] - dragOffset.x) * 0.06)
	dragOffset.y = dragOffset.y + ((math.floor(canvasSize[2] * 0.5) - panningTo[2] - dragOffset.y) * 0.06)
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
	if button == 0 then
		oldMousePos = position
		mouseDown = isButtonDown
		
		if isButtonDown then
			clickTimeRemaining = clickTime
		elseif clickTimeRemaining > 0 then
			clickTimeRemaining = 0
			
			if doubleClickCooldown > 0 then
				leftClick(position, true)
			else
				leftClick(position)
			end
		end
	end
end

function leftClick(clickPos, isDouble)
	local xRange = {}
	local yRange = {}
	local clicked = nil
	
	for research, tbl in pairs(researchTree) do
		xRange = {tbl.position[1] + dragOffset.x - (iconSizes * 0.5) - 1, tbl.position[1] + dragOffset.x + (iconSizes * 0.5) + 1}
		if clickPos[1] > xRange[1] and clickPos[1] < xRange[2] then
		
			yRange = {tbl.position[2] + dragOffset.y - (iconSizes * 0.5) - 1, tbl.position[2] + dragOffset.y + (iconSizes * 0.5) + 1}
			if clickPos[2] > yRange[1] and clickPos[2] < yRange[2] then
				if tbl.state ~= "hidden" then
					clicked = research
				end
				break
			end
		end
	end
	
	if isDouble then
		if selected == clicked then
			researchButton()
		else
			selected = clicked
			doubleClickCooldown = doubleClickTime
		end
	else
		if clicked then
			doubleClickCooldown = doubleClickTime
		end
		selected = clicked
	end
	
	updateInfoPanel()
	draw()
end


-- Research tree functions
function verifyAcronims()
	local data = root.assetJson("/interface/scripted/fu_researchtreegui/researchData.config")
	local found = false
	local missing = nil
	
	for res1, _ in pairs(data.researchTree) do
		found = false
		for _, res2 in pairs(acronyms) do
			if res1 == res2 then
				found = true
				break
			end
		end
		
		if not found then
			if missing then
				missing = missing.." - "..res1
			else
				missing = res1
			end
		end
	end
	
	if not missing then
		return true
	else
		widget.setText("title", "^red;ERROR - Researches missing acronyms")
		widget.setText("text", missing)
		return false
	end
end

function buildStates()
	researchTree = root.assetJson("/interface/scripted/fu_researchtreegui/researchData.config").researchTree
	
	local dataString = status.statusProperty("FUresearch", "")
	local insertingString = ""
	local splitString = {}
	local splitpos = 0
	
	local _, count = string.gsub(dataString, ",", "")
	for i = 1, count do
		splitpos = string.find(dataString, ",")
		insertingString = string.sub(dataString, 1, splitpos)
		dataString = string.gsub(dataString, insertingString, "")
		
		insertingString = string.gsub(insertingString, ",", "")
		table.insert(splitString, insertingString)
	end
	
	local isAvailable = true
	for _, acr in ipairs(splitString) do
		if acronyms[acr] and researchTree[acronyms[acr]] then
			researchTree[acronyms[acr]].state = "researched"
			
			if researchTree[acronyms[acr]].children then
				for _, child in ipairs(researchTree[acronyms[acr]].children) do
					if researchTree[child].state ~= "researched" then
						isAvailable = true
						
						for research, tbl in pairs(researchTree) do
							if research ~= acronyms[acr] and tbl.children then
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
	
	for _, research in ipairs(hiddenResearch) do
		if not researchTree[research].state then
			hideResearchBranch(research)
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
		if type(researchTree[research].price) == "table" then
			for _, tbl in ipairs(researchTree[research].price) do
				local isCurrency = false
				
				for _, curTbl in ipairs(currencies) do
					if tbl[1] == curTbl[1] then
						isCurrency = true
						break
					end
				end
				
				if isCurrency then
					if player.currency(tbl[1]) < tbl[2] then
						return false
					end
				else
					if player.hasCountOfItem(tbl[1]) < tbl[2] then
						return false
					end
				end
			end
		else
			if player.currency(defaultCurrency) < researchTree[research].price then
				return false
			end
		end
	end
	
	if consume then
		if type(researchTree[research].price) == "table" then
			for _, tbl in ipairs(researchTree[research].price) do
				local isCurrency = false
				
				for _, curTbl in ipairs(currencies) do
					if tbl[1] == curTbl[1] then
						isCurrency = true
						break
					end
				end
				
				if isCurrency then
					player.consumeCurrency(tbl[1], tbl[2])
				else
					player.consumeItem({name = tbl[1], count = tbl[2]}, true)
				end
			end
		else
			player.consumeCurrency(defaultCurrency, researchTree[research].price)
		end
	end
	
	return true
end

--		Cheat codes
-- nocosttoogreat					- Toggle free researches
-- iamabeaconofknowledge			- Research everything
-- forgottenmemories				- Reset researches
-- revealourselves					- Unhides all researches
-- nostringsonme					- Disables "read only" mode
-- kotlgiffmana	[acronym string]	- Research the specified acronyms
-- backtothepast					- Reset research currency to 0

cheats = {
	nocosttoogreat = function()
		if noCost then
			noCost = false
		else
			noCost = true
		end
	end,
	
	iamabeaconofknowledge = function()
		local str = ""
		for acr, _ in pairs(acronyms) do
			str = str..acr..","
		end
		
		status.setStatusProperty("FUresearch", str)
		buildStates()
	end,
	
	forgottenmemories = function()
		local data = root.assetJson("/interface/scripted/fu_researchtreegui/researchData.config")
		local researched = ""
		for _, research in ipairs(data.initiallyResearched) do
			for acr, res in pairs(acronyms) do
				if res == research and not string.find(researched, acr..",") then
					local str = researched..acr..","
					status.setStatusProperty("FUresearch", str)
					break
				end
			end
		end
		
		buildStates()
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
		if text then
			text = string.gsub(text, "kotlgiffmana ", "")
			text = string.upper(text)
			status.setStatusProperty("FUresearch", status.statusProperty("FUresearch", "")..text..",")
			
			buildStates()
		end
	end,
	
	backtothepast = function()
		for _, tbl in ipairs(currencies) do
			player.consumeCurrency(tbl[1], player.currency(tbl[1]))
		end
	end,
}

function cheat(wd)
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

