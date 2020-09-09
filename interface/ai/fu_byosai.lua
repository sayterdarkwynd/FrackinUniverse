require "/scripts/util.lua"
require "/scripts/pathutil.lua"
require "/interface/objectcrafting/fu_racialiser/fu_racialiser.lua"
require "/zb/zb_textTyper.lua"
require "/zb/zb_util.lua"

function init()
	textData = {}
	textUpdateDelay = config.getParameter("textUpdateDelay")
	chatterSound = config.getParameter("chatterSound")
	local sailImages = root.assetJson("/ai/ai.config").species
	local race = player.species()
	sailImage = config.getParameter("sailImage")
	sailImage.aiImage.image = sailImage.aiImage.image:gsub("<fileName>", sailImages[race].aiFrames)
	sailImage.aiImage.defaultUpdateTime = sailImage.aiImage.updateTime
	sailImage.aiImage.currentFrame = 0
	sailImage.scanlines.defaultUpdateTime = sailImage.scanlines.updateTime
	sailImage.scanlines.currentFrame = 0
	sailImage.static.image = sailImage.static.image:gsub("<fileName>", sailImages[race].staticFrames)
	sailImage.static.defaultUpdateTime = sailImage.static.updateTime
	sailImage.static.currentFrame = 0
	sailImage.aiFaceCanvas = widget.bindCanvas("aiFaceCanvas")
	updateAiImage()
	states = config.getParameter("states")
	state = {}
	if world.getProperty("fuChosenShip") then
		changeState("shipChosen")
	else
		changeState("initial")
	end
	
	pane.playSound(chatterSound, -1)
	
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
		if sailImage.aiImage.updateTime <= 0 then
			sailImage.aiImage.currentFrame = updateFrame(sailImage.aiImage)
			sailImage.aiImage.updateTime = sailImage.aiImage.defaultUpdateTime
		else
			sailImage.aiImage.updateTime = sailImage.aiImage.updateTime - dt
		end
	else
		pane.stopAllSounds(chatterSound)
		-- change the ai image to the idle one if there is no text being typed
		if sailImage.aiImage.updateTime <= 0 then
			sailImage.aiImage.currentFrame = 0
			sailImage.aiImage.image = sailImage.aiImage.image:gsub(":talk", ":idle")
			sailImage.aiImage.updateTime = sailImage.aiImage.defaultUpdateTime
		else
			sailImage.aiImage.updateTime = sailImage.aiImage.updateTime - dt
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
		
		-- State specific state change stuff
		if newState == "fuShipChosen" then
			byos()
			changeState("shipChosen")
		elseif newState == "vanillaShipChosen" then
			racial()
			changeState("shipChosen")
		end
		
		textData = {}
		textTyper.init(textData, state.text or "WARNING! MISSING TEXT FOR STATE " .. tostring(newState))
	else
		textData = {}
		textTyper.init(textData, state.text or "ERROR! " .. tostring(newState) .. "STATE NOT DEFINED")
	end
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
	sailImage.aiFaceCanvas:drawImage(sailImage.aiImage.image:gsub("<frame>", sailImage.aiImage.currentFrame), {0,0})
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
		
		elseif buttonType == "Racial" then
		
		else
			textData = {}
			textTyper.init(textData, state.text or "ERROR! INVALID BUTTON PRESSED")
		end
	end
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
		pane.dismiss()
	end
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
		pane.dismiss()
	end
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