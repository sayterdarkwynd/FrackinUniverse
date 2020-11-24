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
	generateShipLists()

	-- temp stuff for pre-choosable BYOS
	byosItems = config.getParameter("byosItems")
end

function generateShipLists()
	ship.buildableShips = {}
	ship.upgradableShips = {}
	local playerRace = player.species()
	for id, data in pairs (ship.shipConfig) do
		if id == "vanilla" then
			ship.vanillaShip = data
		elseif id == "racial" then
			--[[local racialShipData = root.assetJson("/universe_server.config").speciesShips
			local raceOverrides = root.assetJson("/interface/objectcrafting/fu_racializer/fu_racializer_racetableoverride.config")
			local races
			if data.disallowOtherRaceShips then
				races = {playerRace}
			elseif data.whitelistedRaces or data.blacklistedRaces then
				local allRaces = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
				races = {}
				for _, race in ipairs (allRaces) do
					if data.whitelistedRaces then
						if data.whitelistedRaces[race] or race == playerRace then
							table.insert(races, race)
						end
					else	-- blacklistedRaces
						if not data.blacklistedRaces[race] or race == playerRace then
							table.insert(races, race)
						end
					end
				end
			else
				races = root.assetJson("/interface/windowconfig/charcreation.config").speciesOrdering
			end
			for _, race in ipairs (races) do
				local shipData = {}
				shipData.type = racialShipData[race]
				shipData.startingLevel = ship.shipConfig.racial.shipLevel + 1
				local succeded, raceData = pcall(root.assetJson, "/species/" .. race .. ".species")
				if succeded and raceData then
					shipData.name = raceData.charCreationTooltip.title
				else
					shipData.name = race
				end
				shipData.icon = race .. "male.png"
				local succeded2, previewImage = pcall(getShipImage, shipData.type[shipData.startingLevel])
				if succeded2 then
					shipData.previewImage = previewImage
				else
					sb.logInfo(sb.printJson(previewImage))
				end
				shipData.mode = "Upgradable"
				if raceOverrides[race] then
					shipData.name = raceOverrides[race].name or shipData.name
					shipData.icon = raceOverrides[race].icon or shipData.icon
				end
				shipData.name = shipData.name .. " Racial Ship"
				shipData.icon = "/interface/title/" .. shipData.icon
				shipData.id = race .. "racial"
				table.insert(ship.upgradableShips, shipData)
			end ]]--
		else
			-- make this less bad
			if data.raceWhitelist and not data.raceWhitelist[playerRace] then

			elseif data.raceBlacklist and data.raceBlacklist[playerRace]  and not data.raceWhitelist then

			else
				data.id = id
				if type(data.ship) == "table" then
					data.mode = "Upgradable"
					data.previewImage = getShipImage(data.ship[1])
					table.insert(ship.upgradableShips, data)
				else
					data.mode = "Buildable"
					if string.find(data.ship, "/") then
						data.previewImage = getShipImage(data.ship)
						data = nil
						sb.logWarn("Structure file BYOS ships not yet implemented, removing " .. id)
					end
					table.insert(ship.buildableShips, data)
				end
			end
		end
	end

	table.sort(ship.buildableShips, compareByName)
	table.sort(ship.upgradableShips, compareByName)
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
		-- to allow gsubing without changing the original value
		local text = state.text
		local path = state.path

		-- State specific state change stuff
		if newState == "frackinShipChosen" then
			createShip()
			changeState("shipChosen")
			return
		elseif newState == "vanillaShipChosen" then
			createShip(true)
			changeState("shipChosen")
			return
		elseif newState == "frackinShipSelected" then
			if text and ship.selectedShip then
				text = text:gsub("<shipName>", tostring(ship.selectedShip.name)):gsub("<shipMode>", tostring(ship.selectedShip.mode))
			end
			if path and ship.selectedShip then
				path = path:gsub("<shipMode>", string.lower(tostring(ship.selectedShip.mode)))
			end
		elseif newState == "frackinShipChoice" then
			--widget.setVisible("buttonByos", true)
			--widget.setVisible("buttonUpgradable", true)
			widget.setVisible("root.shipList", true)
			for i = 1, 3 do
				widget.setButtonEnabled("button" .. i, false)
			end
			--widget.setSize("root", {144,118})
			if ship.selectedShip and ship.selectedShip.mode == "Upgradable" then
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

		if path then
			widget.setText("path", path)
		end
		typeText(text or "WARNING! MISSING TEXT FOR STATE " .. tostring(newState))
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
			populateShipList(ship.buildableShips)
		elseif buttonType == "Upgradable" then
			widget.setButtonEnabled("buttonByos", true)
			widget.setButtonEnabled("buttonUpgradable", false)
			populateShipList(ship.upgradableShips)
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
		if ship.selectedShip and shipData.id == ship.selectedShip.id then
			widget.setListSelected("root.shipList", listItemName)
			shipSelected("shipList")
		end
	end
end

function createShip(vanilla)
	if not world.getProperty("fuChosenShip") then
		world.setProperty("fuChosenShip", true)
		if vanilla then
			player.upgradeShip(ship.vanillaShip.shipUpgrades)
			-- remove after restoring T0 ships
			race = player.species()
			count = racialiserBootUp()
			parameters = getBYOSParameters("techstation", true, _)
			player.giveItem({name = "fu_byostechstation", count = 1, parameters = parameters})
		else
			-- maybe try make this unnecessary?
			if ship.selectedShip.useOld then
				byos()
			else
				if ship.selectedShip.mode == "Buildable" then
					if string.find(ship.selectedShip.ship, "/") then
						sb.logWarn("STRUCTURE FILE SHIP SUPPORT NOT YET IMPLEMENTED")
					else
						world.sendEntityMessage("frackinshiphandler", "createShip", ship.selectedShip, player.species())
					end
				elseif ship.selectedShip.mode == "Upgradable" then
					sb.logWarn("UPGRADABLE SHIPS NOT YET IMPLEMENTED")
				else
					sb.logError("INVALID SHIP MODE DETECTED")
				end
				player.startQuest("fu_byos")
			end
		end
	end
	pane.dismiss()
end

function getShipImage(file)
	if file then
		local shipConfig = root.assetJson(file)
		local shipImage = shipConfig.backgroundOverlays[1].image
		if string.sub(shipImage, 1, 1) ~= "/" then
			local reversedFile = string.reverse(file)
			local snipLocation = string.find(reversedFile, "/")
			local shipImagePathGsub = string.sub(file, -snipLocation + 1)
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

function racialiserBootUp()
	raceInfo = root.assetJson("/interface/objectcrafting/fu_racialiser/fu_raceinfo.config").raceInfo
	for num, info in pairs (raceInfo) do
		if info.race == race then
			return num
		end
	end
	return 0
end