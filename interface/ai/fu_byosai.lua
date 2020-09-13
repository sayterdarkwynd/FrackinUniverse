require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require "/interface/objectcrafting/fu_racialiser/fu_racialiser.lua"
require "/zb/zb_textTyper.lua"
require "/zb/zb_util.lua"

function init()
	textUpdateDelay = config.getParameter("textUpdateDelay")
	chatterSound = config.getParameter("chatterSound")
	local sailImages = root.assetJson("/ai/ai.config").species
	local race = player.species()
	local aiImageFile = sailImages[race].aiFrames
	sailImage = config.getParameter("sailImage")
	sailImage.aiImage.talk.image = sailImage.aiImage.talk.image:gsub("<fileName>", aiImageFile)
	sailImage.aiImage.talk.defaultUpdateTime = sailImage.aiImage.talk.updateTime
	sailImage.aiImage.talk.currentFrame = 0
	sailImage.aiImage.idle.image = sailImage.aiImage.idle.image:gsub("<fileName>", aiImageFile)
	sailImage.aiImage.idle.defaultUpdateTime = sailImage.aiImage.idle.updateTime
	sailImage.aiImage.idle.currentFrame = 0
	sailImage.scanlines.defaultUpdateTime = sailImage.scanlines.updateTime
	sailImage.scanlines.currentFrame = 0
	sailImage.static.image = sailImage.static.image:gsub("<fileName>", sailImages[race].staticFrames)
	sailImage.static.defaultUpdateTime = sailImage.static.updateTime
	sailImage.static.currentFrame = 0
	sailImage.aiFaceCanvas = widget.bindCanvas("aiFaceCanvas")
	states = config.getParameter("states")
	state = {}
	if world.getProperty("fuChosenShip") then
		changeState("shipChosen")
	else
		changeState("initial")
	end
	updateAiImage()
	
	pane.playSound(chatterSound, -1)
	
	ship = {}
	ship.shipConfig = root.assetJson("/frackinship/configs/ships.config")
	
	-- temp stuff for pre-choosable BYOS
	defaultShipUpgrade = config.getParameter("defaultShipUpgrade")
	byosItems = config.getParameter("byosItems")
end

function update(dt)
	-- Text typing and AI animation
	if not textData.isFinished then
		if textUpdateDelay <= 0 then
			textTyper.update(textData, "root.text")
			textUpdateDelay = config.getParameter("textUpdateDelay")
		else
			textUpdateDelay = textUpdateDelay - 1
		end
		if sailImage.aiImage[sailImage.aiImage.mode].updateTime <= 0 then
			sailImage.aiImage[sailImage.aiImage.mode].currentFrame = updateFrame(sailImage.aiImage[sailImage.aiImage.mode])
			sailImage.aiImage[sailImage.aiImage.mode].updateTime = sailImage.aiImage[sailImage.aiImage.mode].defaultUpdateTime
		else
			sailImage.aiImage[sailImage.aiImage.mode].updateTime = sailImage.aiImage[sailImage.aiImage.mode].updateTime - dt
		end
	else
		pane.stopAllSounds(chatterSound)
		-- change the ai image to the idle one if there is no text being typed
		if sailImage.aiImage[sailImage.aiImage.mode].updateTime <= 0 then
			sailImage.aiImage.mode = "idle"
			sailImage.aiImage[sailImage.aiImage.mode].currentFrame = updateFrame(sailImage.aiImage[sailImage.aiImage.mode])
			sailImage.aiImage[sailImage.aiImage.mode].updateTime = sailImage.aiImage[sailImage.aiImage.mode].defaultUpdateTime
		else
			sailImage.aiImage[sailImage.aiImage.mode].updateTime = sailImage.aiImage[sailImage.aiImage.mode].updateTime - dt
		end
		if not world.getProperty("fuChosenShip") then
			widget.setButtonEnabled("showMissions", true)
			widget.setButtonEnabled("showCrew", true)
		end
	end
	
	-- Scan lines animation
	if sailImage.scanlines.updateTime <= 0 then
		sailImage.scanlines.currentFrame = updateFrame(sailImage.scanlines)
		sailImage.scanlines.updateTime = sailImage.scanlines.defaultUpdateTime
	else
		sailImage.scanlines.updateTime = sailImage.scanlines.updateTime - dt
	end
	
	-- Static animation
	if sailImage.static.updateTime <= 0 then
		sailImage.static.currentFrame = updateFrame(sailImage.static)
		sailImage.static.updateTime = sailImage.static.defaultUpdateTime
	else
		sailImage.static.updateTime = sailImage.static.updateTime - dt
	end
	
	updateAiImage()
end

function changeState(newState)
	if states[newState] then
		-- Generic state change stuff
		state = states[newState]
		if state.previousState then
			widget.setButtonEnabled("buttonBack", true)
		else
			widget.setButtonEnabled("buttonBack", false)
		end
		if state.buttons then
			for i = 1, 3 do
				if state.buttons[i] then
					widget.setButtonEnabled("button" .. i, true)
					widget.setText("button" .. i, state.buttons[i].name)
				else
					widget.setButtonEnabled("button" .. i, false)
					widget.setText("button" .. i, "")
				end
			end
		else
			for i = 1, 3 do
				widget.setButtonEnabled("button" .. i, false)
				widget.setText("button" .. i, "")
			end
		end
		widget.setVisible("root", true)
		widget.setVisible("buttonByos", false)
		widget.setVisible("buttonUpgradable", false)
		widget.setVisible("root.shipList", false)
		widget.setVisible("preview", false)
		widget.setSize("root", {144,136})
		widget.clearListItems("root.shipList")
		
		-- State specific state change stuff
		if newState == "frackinShipChosen" then
			byos()
			changeState("shipChosen")
		elseif newState == "vanillaShipChosen" then
			racial()
			changeState("shipChosen")
		elseif newState == "frackinShipSelected" then
			-- temp (remove when choosable byos is added)
			--ship.selectedShip.name = "Default BYOS"
			--ship.selectedShip.mode = "Buildable"
			if state.text and ship.selectedShip then	-- improve this later
				state.text = state.text:gsub("<shipName>", tostring(ship.selectedShip.name)):gsub("<shipMode>", tostring(ship.selectedShip.mode))
			end
			if state.path and ship.selectedShip then
				state.path = state.path:gsub("<shipMode>", string.lower(tostring(ship.selectedShip.mode)))
			end
		elseif newState == "frackinShipChoice" then
			widget.setVisible("buttonByos", true)
			widget.setVisible("buttonUpgradable", true)
			widget.setVisible("root.shipList", true)
			for i = 1, 3 do
				--widget.setButtonEnabled("button" .. i, false)
			end
			widget.setSize("root", {144,118})
			if ship.selectedShip and ship.selectedShip.mode == "Racial" then
				buttonPress("buttonUpgradable")
			else
				buttonPress("buttonByos")
			end
		elseif newState == "frackinShipPreview" then
			widget.setVisible("root", false)
			if ship.selectedShip then
				widget.setVisible("preview", true)
				widget.setImage("preview", ship.selectedShip.previewImage or "")
			end
		end
		
		if state.path then
			widget.setText("path", state.path)
		end
		typeText(state.text or "WARNING! MISSING TEXT FOR STATE " .. tostring(newState))
	else
		typeText(textData, "ERROR! " .. tostring(newState) .. " STATE NOT DEFINED")
	end
end

function typeText(text)
	sailImage.aiImage.mode = "talk"
	textData = {}
	textTyper.init(textData, text)
	pane.playSound(chatterSound, -1)
end

function updateFrame(imageTable)
	imageTable.currentFrame = imageTable.currentFrame + 1
	if imageTable.currentFrame >= imageTable.frames then
		imageTable.currentFrame = 0
	end
	return imageTable.currentFrame
end

function updateAiImage()
	sailImage.aiFaceCanvas:clear()
	sailImage.aiFaceCanvas:drawImage(sailImage.aiImage[sailImage.aiImage.mode].image:gsub("<frame>", sailImage.aiImage[sailImage.aiImage.mode].currentFrame), {0,0})
	sailImage.aiFaceCanvas:drawImage(sailImage.scanlines.image:gsub("<frame>", sailImage.scanlines.currentFrame), {0,0}, nil, "#FFFFFF"..zbutil.ValToHex(sailImage.scanlines.opacity), false)
	sailImage.aiFaceCanvas:drawImage(sailImage.static.image:gsub("<frame>", sailImage.static.currentFrame), {0,0}, nil, "#FFFFFF"..zbutil.ValToHex(sailImage.static.opacity), false)
end

function uninit()
	pane.stopAllSounds(chatterSound)
end

function buttonPress(button)
	if button then
		local buttonType = button:gsub("button", "")
		if buttonType == "1" then
			changeState(state.buttons[1].newState)
		elseif buttonType == "2" then
			changeState(state.buttons[2].newState)
		elseif buttonType == "3" then
			changeState(state.buttons[3].newState)
		elseif buttonType == "Back" then
			changeState(state.previousState)
		elseif buttonType == "Byos" then
			widget.setButtonEnabled("buttonByos", false)
			widget.setButtonEnabled("buttonUpgradable", true)
			--populateShipList(ship.byosShips)
		elseif buttonType == "Upgradable" then
			widget.setButtonEnabled("buttonByos", true)
			widget.setButtonEnabled("buttonUpgradable", false)
			--populateShipList(ship.racialShips)
		else
			typeText("ERROR! INVALID BUTTON PRESSED")
		end
	end
end

function shipSelected(args)
	local selected = widget.getListSelected("root.shipList")
	if selected then
		selected = "root.shipList."..selected
		ship.selectedShip = widget.getData(selected)
		for i = 1, 2 do
			widget.setButtonEnabled("button" .. i, true)
		end
	end
end

function generateByosShipList()
	ship.byosShips = {}
	for _, shipInfo in pairs (ship.shipConfig.byosShips) do
		local shipData = shipInfo
		shipData.mode = "Buildable"
		table.insert(ship.byosShips, shipData)
	end
	table.sort(ship.byosShips, compareByName)
end

function generateRacialShipList()
	ship.racialShips = {}
	local racialShipData = root.assetJson("/universe_server.config").speciesShips
	local raceOverrides = root.assetJson("/interface/objectcrafting/fu_racializer/fu_racializer_racetableoverride.config")
	local races
	if ship.shipConfig.racialShips.allowOtherRaceShips then
		races = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
	else
		races = {player.species()}
	end
	for _, race in pairs (races) do
		local shipData = {}
		shipData.type = racialShipData[race]
		shipData.startingLevel = ship.shipConfig.racialShips.shipLevel
		local succeded, raceData = pcall(root.assetJson, "/species/" .. race .. ".species")
		if succeded and raceData then
			shipData.name = raceData.charCreationTooltip.title
		else
			shipData.name = race
		end
		shipData.icon = race .. "male.png"
		local succeded2, previewImage = pcall(getStructureShipImage, shipData.type[shipData.startingLevel])
		if succeded2 then
			shipData.previewImage = previewImage
		else
			sb.logInfo(sb.printJson(previewImage))
		end
		shipData.mode = "Racial"
		if raceOverrides[race] then
			shipData.name = raceOverrides[race].name or shipData.name
			shipData.icon = raceOverrides[race].icon or shipData.icon
		end
		shipData.name = shipData.name .. " Racial Ship"
		shipData.icon = "/interface/title/" .. shipData.icon
		table.insert(ship.racialShips, shipData)
	end
	table.sort(ship.racialShips, compareByName)
end

function populateShipList(shipList)
	widget.clearListItems("root.shipList")
	for _, shipData in ipairs (shipList) do
		local listItemName = widget.addListItem("root.shipList")
		local listItem = "root.shipList."..listItemName	
		widget.setText(listItem..".name", shipData.name)
		widget.setData(listItem, shipData)
		if shipData.icon then
			widget.setImage(listItem..".icon", shipData.icon)
		end
		if ship.selectedShip and ship.selectedShip.type == shipData.type and ship.selectedShip.name == shipData.name then
			widget.setListSelected("root.shipList", listItemName)
			shipSelected("shipList")
		end
	end
end

function getStructureShipImage(file)
	if file then
		local shipConfig = root.assetJson(file)
		local reversedFile = string.reverse(file)
		local snipLocation = string.find(reversedFile, "/")
		local shipImagePathGsub = string.sub(file, -snipLocation + 1)
		local shipImage = shipConfig.backgroundOverlays[1].image
		if not string.find(shipImage, "/") then
			shipImage = file:gsub(shipImagePathGsub, shipImage)
		end
		return shipImage
	end
end

-- Copied from terminal code
function compareByName(shipA, shipB)
	local a = comparableName(shipA.name)
	local b = comparableName(shipB.name)
	return a < b
end

function comparableName(name)
	return name:gsub('%^#?%w+;', '') -- removes the color encoding from names, e.g. ^blue;Madness^reset; -> Madness
		:gsub('ū', 'u')
		:upper()
end

function byos()
	if not world.getProperty("fuChosenShip") then
		player.startQuest("fu_byos")
		player.startQuest("fu_shipupgrades")
		for _, recipe in pairs (root.assetJson("/interface/ai/fu_byosrecipes.config")) do
			player.giveBlueprint(recipe)
		end
		if byosItems then
			for _,byosItem in pairs (byosItems) do
				player.giveItem(byosItem)
			end
		end
		world.sendEntityMessage("bootup", "byos", player.species())
		world.setProperty("fuChosenShip", true)
	end
	pane.dismiss()
end

function racial()
	if not world.getProperty("fuChosenShip") then
		race = player.species()
		count = racialiserBootUp()
		parameters = getBYOSParameters("techstation", true, _)
		player.giveItem({name = "fu_byostechstation", count = 1, parameters = parameters})
		player.startQuest("fu_shipupgrades")
		player.upgradeShip(defaultShipUpgrade)
		world.setProperty("fuChosenShip", true)
	end
	pane.dismiss()
end

function racialiserBootUp()
	raceInfo = root.assetJson("/interface/objectcrafting/fu_racialiser/fu_raceinfo.config").raceInfo
	for num, info in pairs (raceInfo) do
		if info.race == race then
			return num
		end
	end
	return 0
end