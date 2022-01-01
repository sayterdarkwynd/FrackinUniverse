
require "/scripts/util.lua"
require "/zb/zb_textTyper.lua"
require "/zb/zb_util.lua"


-----------------------------------------------------------------------------------------------------------------------------------------------------
--	FUNCTION ADDITIONS
-----------------------------------------------------------------------------------------------------------------------------------------------------
--	Small additions to already present functions

textTyper.initOrig = textTyper.init
function textTyper.init(textData, str, sound)
	doneTalking = false
	textTyper.initOrig(textData, str, sound)
end

textTyper.skipOrig = textTyper.skip
function textTyper.skip(textData, wd)
	doneTalking = false
	textTyper.skipOrig(textData, wd)
end


-----------------------------------------------------------------------------------------------------------------------------------------------------
--	UNSAFE FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------------------
--	These functions behave normally, and are called from the GUI pane.
--	They serve mostly to call the main functions in a safe enviorment.
--	Do not change anything here unless you need to modify some direct interaction that for some reason can't be done in the safe functions.

cfg = {}
GUI = nil
charDeltaCounter = 0
noError = true
doneTalking = false
errorString = "An error has occured.\n\nPlease report this on the Steam page or Discord server with a log attached.\n\nMeanwhile, you can click any of the buttons to open the vanilla version of SAIL."
-- 'errorString' is overriden by whatever is in 'cfg.TextData.strings.error'

function init()
	local status, err = pcall(initSafe)
	if not status then
		script.setUpdateDelta(0)
		enableFailsafe(err)
	end

	if noError then
		status, err = pcall(customDatainit)
		if not status then
			enableFailsafe(err)
		end
	end
end

function uninit()
	if cfg.TextData then
		if type(cfg.TextData.soundPlaying) == "table" then
			for _, snd in ipairs(cfg.TextData.soundPlaying) do
				pane.stopAllSounds(snd)
			end
		elseif cfg.TextData.soundPlaying then
			pane.stopAllSounds(cfg.TextData.soundPlaying)
		end
	end
end

function update(dt)
	if noError then
		local status, err = pcall(updateSafe, dt)
		if not status then
			script.setUpdateDelta(0)
			enableFailsafe(err)
		end
	end
end

function buttonMain(wd)
	if noError then
		local status, err = pcall(buttonMainSafe, wd)
		if not status then
			enableFailsafe(err)
		end
	else
		player.interact("OpenAiInterface")
		pane.dismiss()
	end
end

function missionSelected()
	if noError then
		local status, err = pcall(missionSelectedSafe)
		if not status then
			enableFailsafe(err)
		end
	end
end

function crewSelected()
	if noError then
		local status, err = pcall(crewSelectedSafe)
		if not status then
			enableFailsafe(err)
		end
	end
end

function miscSelected()
	if noError then
		local status, err = pcall(miscSelectedSafe)
		if not status then
			enableFailsafe(err)
		end
	end
end

function enableFailsafe(err)
	noError = false

	if cfg and cfg.TextData then cfg.TextData.isFinished = true end

	widget.setVisible("root.text", true)
	widget.setText("root.text", errorString)

	sb.logError("")
	sb.logError("[FU] ERROR WHILE EXECUTING CUSTOM SAIL:")
	sb.logError("%s", err)
	sb.logError("")
end

-----------------------------------------------------------------------------------------------------------------------------------------------------
--	SAFE FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------------------
--	These functions are running in a safe enviorment - Should one of them run into an error, the GUI will not freeze and stop working.
--	Instead, any of the buttons (except the close button) will open the vanilla SAIL GUI so players could continue playing without waiting for a fix.
--	However, this does not prevent stack overflows, or errors that cause crashes. (such as a function expecting a string of an image path, but recieving a non-absolute path, or a path leading to a non-image)

function initSafe()
	cfg = root.assetJson("/zb/newSail/data.config")
	errorString = cfg.TextData.strings.error

	GUI = cfg.GUI
	GUI.canvas = widget.bindCanvas("aiFaceCanvas")
	GUI.missionViewing = "main"

	widget.setText("windowTitle", cfg.GUI.title)
	widget.setText("windowSubtitle", cfg.GUI.subtitle)
	widget.setImage("windowIcon", cfg.GUI.titleIcon)

	buildCurrencyList()
	textTyper.init(cfg.TextData, cfg.TextData.strings.intro, customData.chatterSound or cfg.TextData.sound)
end

function resetGUI()
	widget.setVisible("root", true)
	widget.setSize("root", {144,136})

	widget.clearListItems("root.currencyList")
	widget.setVisible("root.currencyList", false)

	widget.clearListItems("root.missionList")
	widget.setVisible("root.missionList", false)

	widget.clearListItems("root.crewList")
	widget.setVisible("root.crewList", false)

	widget.clearListItems("root.miscList")
	widget.setVisible("root.miscList", false)

	textTyper.skip(cfg.TextData, "root.text")
	widget.setText("root.text", "")
	widget.setVisible("root.text", true)

	widget.setText("path", "root/sail/ui/main")

	widget.setButtonEnabled("buttonMain", true)
	widget.setButtonEnabled("buttonMissions", true)
	widget.setButtonEnabled("buttonCrew", true)
	widget.setButtonEnabled("buttonMisc", true)
	widget.setButtonEnabled("buttonScreenRight", true)

	widget.setVisible("switchMissionSecondary", false)
	widget.setVisible("switchMissionMain", false)
	widget.setVisible("buttonScreenRight", false)
	widget.setVisible("buttonScreenLeft", false)

	for i = 1, 3 do
		widget.setVisible("aiDataItemSlot"..i, false)
	end

	-- GUI.talker.emote = "idle"
	GUI.list.viewing = nil
	GUI.dismissConfirmTimer = 0
	GUI.talker.frameTimer = 0
	GUI.talker.frame = 0

	fuResetGUI()
end

function updateSafe(dt)

	if GUI.customDataUpdateTimer <= 0 then
		GUI.customDataUpdateTimer = GUI.customDataUpdateCooldown
		customDataUpdate()
	else
		GUI.customDataUpdateTimer = GUI.customDataUpdateTimer - dt
	end

	if not customDataInited then return end

	if GUI.dismissConfirmTimer > 0 then
		GUI.dismissConfirmTimer = GUI.dismissConfirmTimer - dt
	else
		widget.setButtonEnabled("buttonScreenRight", true)
	end

	if GUI.crewRequestTimer > 0 then
		GUI.crewRequestTimer = GUI.crewRequestTimer - dt
	elseif GUI.crewRequestTimer > -69 then
		cfg.Data.crew = "pending"
		GUI.crewRequestTimer = -80085
	end

	if GUI.list.viewing then
		if GUI.list.updateTimer > 0 then
			GUI.list.updateTimer = GUI.list.updateTimer - dt
		else
			GUI.list.updateTimer = GUI.list.updateInterval

			if GUI.list.viewing == "currency" then
				populateCurrencyList()

			elseif GUI.list.viewing == "crew" then

				-- Shamelessly stolen from customizable SAIL
				if cfg.Data.crew == "pending" then
					if cfg.Data.crewPromise == nil then
						cfg.Data.crewPromise = world.sendEntityMessage(player.id(), "returnCompanions")
					elseif cfg.Data.crewPromise:succeeded() then
						widget.setVisible("root.crewList", true)
						cfg.Data.crew = cfg.Data.crewPromise:result()
						cfg.Data.crewPromise = nil
						populateCrewList()
					end
				end

				fuCrewViewing()

			else
				GUI.list.viewing = nil
			end
		end
	end

	-- Animate portrait and text
	if cfg.TextData.isFinished then
		if not doneTalking then
			GUI.talker.emote = customData.defaultAnimation or GUI.talker.defaultAnimation
			GUI.talker.frame = 0
			doneTalking = true
		end
	else
		charDeltaCounter = charDeltaCounter + (dt * GUI.talker.speedModifier)
		if 1 / (customData.charactersPerSecond or GUI.talker.charactersPerSecond) <= charDeltaCounter then
			textTyper.scrambling(cfg.TextData)
			textTyper.update(cfg.TextData, "root.text")
			charDeltaCounter = 0
		end
	end

	if customData.aiAnimations and customData.aiAnimations[GUI.talker.emote] then
		if GUI.talker.frameTimer <= 0 then
			GUI.talker.frameTimer = (customData.aiAnimations[GUI.talker.emote].animationCycle or GUI.talker.animations[GUI.talker.emote].animationCycle or GUI.talker.defaultAnimationCycle) / (customData.aiAnimations[GUI.talker.emote].frameNumber or GUI.talker.animations[GUI.talker.emote].frameNumber)
			if GUI.talker.frame >= (customData.aiAnimations[GUI.talker.emote].frameNumber or GUI.talker.animations[GUI.talker.emote].frameNumber)-1 then
				GUI.talker.frame = 0

				if (customData.aiAnimations[GUI.talker.emote].mode or GUI.talker.animations[GUI.talker.emote].mode) == "stop" then
					GUI.talker.emote = customData.defaultAnimation or GUI.talker.defaultAnimation
				end
			else
				GUI.talker.frame = GUI.talker.frame + 1
			end
		else
			GUI.talker.frameTimer = GUI.talker.frameTimer - dt
		end

		GUI.talker.displayImage = string.gsub("/ai/"..(customData.aiAnimations[GUI.talker.emote].frames or GUI.talker.animations[GUI.talker.emote].frames), "<image>", (customData.aiFrames or GUI.talker.imagePath))
		GUI.talker.displayImage = string.gsub(GUI.talker.displayImage, "<index>", GUI.talker.frame)
	else
		if GUI.talker.frameTimer <= 0 then
			GUI.talker.frameTimer = (GUI.talker.animations[GUI.talker.emote].animationCycle or GUI.talker.defaultAnimationCycle) / (GUI.talker.animations[GUI.talker.emote].frameNumber)
			if GUI.talker.frame >= GUI.talker.animations[GUI.talker.emote].frameNumber-1 then
				GUI.talker.frame = 0

				if GUI.talker.animations[GUI.talker.emote].mode == "stop" then
					GUI.talker.emote = customData.defaultAnimation or GUI.talker.defaultAnimation
				end
			else
				GUI.talker.frame = GUI.talker.frame + 1
			end
		else
			GUI.talker.frameTimer = GUI.talker.frameTimer - dt
		end

		GUI.talker.displayImage = string.gsub("/ai/"..GUI.talker.animations[GUI.talker.emote].frames, "<image>", GUI.talker.imagePath)
		GUI.talker.displayImage = string.gsub(GUI.talker.displayImage, "<index>", GUI.talker.frame)
	end

	-- Animate portrait scan lines
	if GUI.scanLines.frameTimer > 0 then
		GUI.scanLines.frameTimer = GUI.scanLines.frameTimer - dt
	else
		GUI.scanLines.frame = (GUI.scanLines.frame + 1) % GUI.scanLines.maxFrames
		GUI.scanLines.frameTimer = GUI.scanLines.frameDelay
	end

	-- Animate portrait static
	GUI.static.frame = (GUI.static.frame + 1) % GUI.static.maxFrames

	draw()
end

function draw()
	GUI.canvas:clear()
	GUI.canvas:drawImage(GUI.talker.displayImage, {0,0})
	GUI.canvas:drawImage(GUI.static.image..":"..GUI.static.frame, {0,0}, nil, "#FFFFFF"..zbutil.ValToHex(customData.staticOpacity or GUI.static.opacity), false)
	GUI.canvas:drawImage(GUI.scanLines.image..":"..GUI.scanLines.frame, {0,0}, nil, "#FFFFFF"..zbutil.ValToHex(customData.scanlineOpacity or GUI.scanLines.opacity), false)
end

function buttonMainSafe(wd)
	if not customDataInited then return end
	textTyper.stopSounds(cfg.TextData)

	if wd == "buttonMain" then
		resetGUI()

		widget.setText("path", "root/sail/ui/overview")
		widget.setVisible("root.currencyList", true)
		widget.setVisible("root.text", false)

		GUI.list.viewing = "currency"
		populateCurrencyList()

	elseif wd == "buttonMissions" then
		resetGUI()
		widget.setSize("root", {144,118})

		widget.setText("path", "root/sail/ui/missions/main")
		widget.setVisible("switchMissionSecondary", true)
		widget.setVisible("switchMissionMain", true)
		widget.setVisible("root.missionList", true)
		widget.setVisible("root.text", false)

		GUI.missionViewing = GUI.missionViewing or "main"
		if GUI.missionViewing == "main" then
			widget.setButtonEnabled("switchMissionSecondary", true)
			widget.setButtonEnabled("switchMissionMain", false)
		else
			widget.setButtonEnabled("switchMissionSecondary", false)
			widget.setButtonEnabled("switchMissionMain", true)
		end

		populateMissionList()
		widget.setText("buttonScreenRight", " GO! >")

		fuButtonMissions()

	elseif wd == "switchMissionMain" then
		resetGUI()
		widget.setSize("root", {144,118})

		widget.setText("path", "root/sail/ui/missions/main")
		widget.setButtonEnabled("switchMissionSecondary", true)
		widget.setButtonEnabled("switchMissionMain", false)
		widget.setVisible("switchMissionSecondary", true)
		widget.setVisible("switchMissionMain", true)
		widget.setVisible("root.missionList", true)
		widget.setVisible("root.text", false)

		GUI.missionViewing = "main"
		populateMissionList()

		fuSwitchMissionMain()

	elseif wd == "switchMissionSecondary" then
		resetGUI()
		widget.setSize("root", {144,118})

		widget.setText("path", "root/sail/ui/missions/secondary")
		widget.setButtonEnabled("switchMissionSecondary", false)
		widget.setButtonEnabled("switchMissionMain", true)
		widget.setVisible("switchMissionSecondary", true)
		widget.setVisible("switchMissionMain", true)
		widget.setVisible("root.missionList", true)
		widget.setVisible("root.text", false)

		GUI.missionViewing = "secondary"
		populateMissionList()

		fuSwitchMissionSecondary()

	elseif wd == "buttonScreenRight" then
		if widget.active("root.missionList") then
			resetGUI()

			if cfg.Data.missionWorld then
				player.warp("InstanceWorld:"..cfg.Data.missionWorld, cfg.Data.warpAnimation or "beam", cfg.Data.warpDeploy)
				pane.dismiss()
			end
		elseif widget.active("root.crewList") then
			if widget.getData("buttonScreenRight") == "dismissConfirm" then
				world.sendEntityMessage(player.id(), 'dismissCompanion', cfg.Data.selectedCrewID)
				widget.setData("buttonScreenRight", nil)
				buttonMainSafe("buttonCrew")
				widget.clearListItems("root.missionList")

				fuDismissConfirm()
			else
				widget.setData("buttonScreenRight", "dismissConfirm")
				widget.setText("buttonScreenRight", "CONFIRM")
				widget.setButtonEnabled("buttonScreenRight", false)
				GUI.dismissConfirmTimer = GUI.dismissConfirmDelay
			end
		elseif widget.active("aiDataItemSlot1") then
			openAIChipCraft()
		end

	elseif wd == "buttonScreenLeft" then
		if widget.active("root.missionList") then
			buttonMainSafe("buttonMissions")
		elseif widget.active("root.crewList") then
			buttonMainSafe("buttonCrew")
		elseif widget.active("aiDataItemSlot1") then
			buttonMainSafe("buttonMisc")
		end

	elseif wd == "buttonCrew" then
		resetGUI()

		local listItem = "root.crewList."..widget.addListItem("root.crewList")
		widget.setText(listItem..".name", "Loading Crew...")
		widget.setVisible(listItem..".portraitCanvas", false)
		widget.setVisible(listItem..".pseudobutton", false)
		widget.setVisible(listItem..".background", false)
		widget.setVisible(listItem..".portraitBG", false)

		widget.setVisible("root.text", false)
		widget.setVisible("root.crewList", true)
		widget.setText("path", "root/sail/ui/crew")
		widget.setText("buttonScreenRight", "DISMISS")
		widget.setData("buttonScreenRight", nil)

		GUI.talker.emote = "unique"
		GUI.list.viewing = "crew"
		GUI.crewRequestTimer = GUI.crewRequestDelay -- Start the whole crew retrieval process

		fuButtonCrew()

	elseif wd == "buttonMisc" then
		resetGUI()

		widget.setText("path", "root/sail/ui/misc")
		widget.setVisible("root.miscList", true)
		populateMiscList()

	else
		widget.setText("root.text", cfg.TextData.strings.buttonError)
	end
end


function buildCurrencyList()
	local cd = root.assetJson("/currencies.config")
	local tbl = {unsorted = {}}

	for cur, dat in pairs(cd) do
		if dat.sail_group then
			if not tbl[dat.sail_group] then
				tbl[dat.sail_group] = {}
			end

			table.insert(tbl[dat.sail_group], dat)
			tbl[dat.sail_group][#tbl[dat.sail_group]].currency = cur
		elseif not dat.sail_hidden then
			table.insert(tbl.unsorted, dat)
			tbl.unsorted[#tbl.unsorted].currency = cur
		end
	end

	local order = {}
	for _, k in ipairs(cd.money.sail_group_order) do
		if k ~= "main" and k ~= "unsorted" and tbl[k] then
			local duplicate = false
			for _, v in ipairs(order) do
				if k == v then
					duplicate = true
					break
				end
			end

			if not duplicate then
				table.insert(order, k)
			end
		end
	end

	table.insert(order, 1, "main")
	table.insert(order, "unsorted")

	cfg.Data.currencies = tbl
	cfg.Data.currencyOrder = order
end

function populateCurrencyList()
	widget.clearListItems("root.currencyList")

	local listItem = ""
	local i = 0

	for o, ord in ipairs(cfg.Data.currencyOrder) do
		if o > 1 and #cfg.Data.currencies[ord] > 0 then
			local secrets = 0
			for currency, dat in pairs(cfg.Data.currencies[ord]) do
				if dat.sail_secret and player.currency(currency) <= 0 then
					secrets = secrets + 1
				end
			end

			if secrets < #cfg.Data.currencies[ord] then
				listItem = "root.currencyList."..widget.addListItem("root.currencyList")
				widget.setText(listItem..".title", cfg.TextData.currencies[ord] or ord)
				widget.setVisible(listItem..".background", false)
				widget.setVisible(listItem..".amount1", false)
				widget.setVisible(listItem..".amount2", false)
				widget.setVisible(listItem..".item1", false)
				widget.setVisible(listItem..".item2", false)
				widget.setVisible(listItem..".title", true)
				widget.setVisible(listItem..".titleBG", true)
			end
		end

		for _, dat in ipairs(cfg.Data.currencies[ord]) do
			if not dat.sail_secret or (dat.sail_secret and player.currency(dat.currency) > 0) then
				local loc = i % 2
				if loc == 0 then
					listItem = "root.currencyList."..widget.addListItem("root.currencyList")
				end

				widget.setItemSlotItem(listItem..".item"..loc+1, dat.representativeItem)
				widget.setText(listItem..".amount"..loc+1, player.currency(dat.currency))
				i = i + 1
			end
		end
	end
end


function populateMissionList()
	widget.clearListItems("root.missionList")

	local listItem
	local replays = {}
	local noMissions = true

	for i, tbl in ipairs(cfg.Data.missions[GUI.missionViewing]) do
		if type(tbl[2]) == "table" then
			local state = "unavailable"

			for _, quest in ipairs(tbl[2]) do
				if player.hasCompletedQuest(quest) then
					state = "complete"
					break
				elseif player.hasQuest(quest) then
					state = "available"
				end
			end

			if state == "complete" then
				table.insert(replays, i)
			elseif state == "available" then
				local dat = root.assetJson(tbl[1])
				if dat then
					listItem = "root.missionList."..widget.addListItem("root.missionList")
					widget.setText(listItem..".title", dat.speciesText.default.buttonText)
					widget.setImage(listItem..".icon", "/ai/"..dat.icon)
					widget.setData(listItem, { index = i, })
					noMissions = false
				end
			end
		else
			if player.hasCompletedQuest(tbl[2]) then
				table.insert(replays, i)

			elseif player.hasQuest(tbl[2]) then
				local dat = root.assetJson(tbl[1])
				if dat then
					listItem = "root.missionList."..widget.addListItem("root.missionList")
					widget.setText(listItem..".title", dat.speciesText.default.buttonText)
					widget.setImage(listItem..".icon", "/ai/"..dat.icon)
					widget.setData(listItem, { index = i, })
					noMissions = false
				end
			end
		end
	end

	if #replays > 0 then
		-- SPACING \o/
		listItem = "root.missionList."..widget.addListItem("root.missionList")
		widget.setVisible(listItem..".background", false)
		widget.setVisible(listItem..".title", false)
		widget.setVisible(listItem..".iconBG", false)
		widget.setVisible(listItem..".icon", false)
		widget.setVisible(listItem..".replayBG", true)
		widget.setVisible(listItem..".replayLabel", true)
		widget.setVisible(listItem..".pseudobutton", false)
	elseif noMissions then
		widget.setVisible("root.text", true)

		if customData.noMissionsSpeech then
			textTyper.init(cfg.TextData, customData.noMissionsSpeech.text or cfg.Speech.noMissionsSpeech.text, customData.chatterSound or cfg.TextData.sound)
			GUI.talker.emote = customData.noMissionsSpeech.animation or cfg.Speech.noMissionsSpeech.animation
			GUI.talker.speedModifier = customData.noMissionsSpeech.speedModifier or cfg.Speech.noMissionsSpeech.speedModifier
		else
			textTyper.init(cfg.TextData, cfg.Speech.noMissionsSpeech.text, customData.chatterSound or cfg.TextData.sound)
			GUI.talker.emote = cfg.Speech.noMissionsSpeech.animation
			GUI.talker.speedModifier = cfg.Speech.noMissionsSpeech.speedModifier
		end
	end

	for _, i in ipairs(replays) do
		local dat = root.assetJson(cfg.Data.missions[GUI.missionViewing][i][1])
		if dat then
			listItem = "root.missionList."..widget.addListItem("root.missionList")
			widget.setText(listItem..".title", dat.speciesText.default.buttonText)
			widget.setImage(listItem..".icon", "/ai/"..dat.icon)
			widget.setData(listItem, { index = i, })
		end
	end
end

function missionSelectedSafe()
	if not customDataInited then return end
	local selected = widget.getListSelected("root.missionList")
	if selected then
		local listData = widget.getData("root.missionList."..selected)
		if listData then
			widget.setSize("root", {144,136})
			local dat = root.assetJson(cfg.Data.missions[GUI.missionViewing][listData.index][1])
			if dat then

				local text = dat.speciesText.default.selectSpeech.text
				if customData.missionsText and customData.missionsText[dat.missionName] and customData.missionsText[dat.missionName].selectSpeech then
					text = customData.missionsText[dat.missionName].selectSpeech.text or text
				end

				textTyper.init(cfg.TextData, text, customData.chatterSound or cfg.TextData.sound)

				if customData.missionsText and customData.missionsText[dat.missionName] and customData.missionsText[dat.missionName].selectSpeech then
					GUI.talker.emote = customData.missionsText[dat.missionName].selectSpeech.animation or "talk"
				end

				widget.setText("path", "root/sail/ui/missions/"..dat.missionName)
				widget.setVisible("switchMissionSecondary", false)
				widget.setVisible("switchMissionMain", false)
				widget.setVisible("buttonScreenRight", true)
				widget.setVisible("buttonScreenLeft", true)
				widget.setVisible("root.missionList", true)
				widget.setVisible("root.text", true)
				widget.clearListItems("root.missionList")

				cfg.Data.missionWorld = dat.missionWorld
				cfg.Data.warpAnimation = dat.warpAnimation
				cfg.Data.warpDeploy = dat.warpDeploy

				local listItem = "root.missionList."..widget.addListItem("root.missionList")
				widget.setVisible(listItem..".pseudobutton", false)
				widget.setImage(listItem..".icon", "/ai/"..dat.icon)
				widget.setText(listItem..".title", dat.speciesText.default.buttonText)
			end
		end
	end
end


function populateCrewList()
	if cfg.Data.crew and type(cfg.Data.crew) == "table" then
		widget.clearListItems("root.crewList")

		if #cfg.Data.crew > 0 then
			for i, tbl in ipairs(cfg.Data.crew) do
				local listItem = "root.crewList."..widget.addListItem("root.crewList")
				local canvas = widget.bindCanvas(listItem..".portraitCanvas")

				for _, portrait in ipairs(tbl.portrait) do
					canvas:drawImage(portrait.image, {-15.5, -19.5})
				end

				widget.setText(listItem..".name", tbl.name)
				widget.setData(listItem, { index = i, })
			end
		else
			widget.setVisible("root.text", true)

			textTyper.init(cfg.TextData, cfg.TextData.strings.noCrew, customData.chatterSound or cfg.TextData.sound)
			if customData.noCrewSpeech then
				textTyper.init(cfg.TextData, customData.noCrewSpeech.text or cfg.Speech.noCrewSpeech.text, customData.chatterSound or cfg.TextData.sound)
				GUI.talker.emote = customData.noCrewSpeech.animation or cfg.Speech.noCrewSpeech.animation
				GUI.talker.speedModifier = customData.noCrewSpeech.speedModifier or cfg.Speech.noCrewSpeech.speedModifier
			else
				textTyper.init(cfg.TextData, cfg.Speech.noCrewSpeech.text, customData.chatterSound or cfg.TextData.sound)
				GUI.talker.emote = cfg.Speech.noCrewSpeech.animation
				GUI.talker.speedModifier = cfg.Speech.noCrewSpeech.speedModifier
			end

			fuPopulateCrewList()
		end
	end
end

function crewSelectedSafe()
	if not customDataInited then return end
	local selected = widget.getListSelected("root.crewList")
	if selected then
		local listData = widget.getData("root.crewList."..selected)
		if listData then
			widget.setVisible("root.text", true)
			widget.setVisible("buttonScreenRight", true)
			widget.setVisible("buttonScreenLeft", true)

			GUI.list.viewing = nil
			GUI.crewRequestTimer = -80085

			local crew = cfg.Data.crew[listData.index]
			if crew then
				local text = crew.description.."\n^cyan;> Species:^white; "..crew.config.species.."\n^cyan;>" --Level:^white; "..crew.config.parameters.level
				textTyper.init(cfg.TextData, text, customData.chatterSound or cfg.TextData.sound)

				widget.setText("path", "root/sail/ui/crew/"..crew.name)
				widget.clearListItems("root.crewList")

				local listItem = "root.crewList."..widget.addListItem("root.crewList")
				widget.setVisible(listItem..".pseudobutton", false)
				widget.setText(listItem..".name", crew.name)

				local canvas = widget.bindCanvas(listItem..".portraitCanvas")
				for _, portrait in ipairs(crew.portrait) do
					canvas:drawImage(portrait.image, {-15.5, -19.5})
				end

				cfg.Data.selectedCrewID = crew.podUuid

				fuCrewSelectedSafe(crew)
			end
		end
	end
end


function populateMiscList()
	widget.clearListItems("root.miscList")

	if player.isAdmin() then
		for _, tbl in ipairs(cfg.Data.miscAdmin) do
			listItem = "root.miscList."..widget.addListItem("root.miscList")
			widget.setText(listItem..".name", tbl[2])
			widget.setImage(listItem..".icon", tbl[3])
			widget.setData(listItem, {tbl[1], tbl[4], tbl[5]})
		end
	end

	-- Hardcoded custom AI button
	local listItem = "root.miscList."..widget.addListItem("root.miscList")
	widget.setText(listItem..".name", "Customisable A.I. Panel")
	widget.setImage(listItem..".icon", "/interface/craftingbutton.png")
	widget.setData(listItem, {"customAI"})

	for _, tbl in ipairs(cfg.Data.misc) do
		listItem = "root.miscList."..widget.addListItem("root.miscList")
		local textBuffer=tbl[2]

		while true do
			local comparatorStr=textBuffer
			varName=textBuffer:match("%%%%(.+)%%%%")
			if varName then
				local varTranslated=""
				if _ENV[varName] then
					local t=_ENV[varName]
					if type(t)=="string" then
						varTranslated=t
					elseif type(t)=="function" then
						local pass,result=pcall(t)
						if pass then varTranslated=result end
					elseif type(t)=="boolean" then
						if t then varTranslated="On" else varTranslated="Off" end
					else
						varTranslated=""
					end
				else
					local argStr=varName:match("%((.+)%)")
					local args={}
					if type(argStr)=="string" then
						for k in (argStr):gmatch("[^,]+") do
							if k=="true" then
								k = true
							elseif k=="false" then
								k = false
							else
								--we're not going into the migraine of numbers vs strings in this process, thankfully.
								local v2=k:match("\"(.+)\"")
								if v2 then k=v2 end
							end
							table.insert(args,k)
						end
					end

					local func=varName:gsub("%("..argStr.."%)","")
					if func=="world.getProperty" then
						func=world.getProperty
					elseif func=="status.statusProperty" then
						func=status.statusProperty
					end

					if type(func)=="function" then
						local result=func(table.unpack(args))
						if pass or true then
							if type(result)=="string" then
								varTranslated=result
							elseif type(result)=="boolean" then
								if result then varTranslated="On" else varTranslated="Off" end
							elseif type(result)=="number" then
								varTranslated=tostring(result)
							else
								varTranslated="-"
							end
						else
							sb.logInfo("newSail misc function label parser:\n%s",result)
							varTranslated="<ERROR>"
						end
					end
				end
				varTranslated=varTranslated or ""
				local varN2=varName:gsub("([^%w])", "%%%1")
				textBuffer=textBuffer:gsub("%%%%"..varN2.."%%%%",varTranslated or "")
			end

			if comparatorStr==textBuffer then
				break
			end
		end

		widget.setText(listItem..".name", textBuffer)
		widget.setImage(listItem..".icon", tbl[3])
		widget.setData(listItem, {tbl[1], tbl[4], tbl[5]})
	end
end

function miscSelectedSafe()
	if not customDataInited then return end
	local selected = widget.getListSelected("root.miscList")
	if selected then
		local listData = widget.getData("root.miscList."..selected)
		if listData then
			buttonMainSafe("buttonMisc")

			if string.lower(listData[1]) == "scriptpane" then
				player.interact("ScriptPane", listData[2])

			elseif string.lower(listData[1]) == "externalscript" then
				require(listData[2])
				if listData[3] then
					_ENV[listData[3]]()
				end

			elseif string.lower(listData[1]) == "openaiinterface" then
				player.interact("OpenAiInterface")
				pane.dismiss()

			elseif listData[1] == "customAI" then
				if root.itemConfig("apexancientaichip") then
					resetGUI()
					textTyper.init(cfg.TextData, cfg.TextData.strings.customAI, customData.chatterSound or cfg.TextData.sound)
					GUI.talker.emote = "talk"

					for i = 1, 3 do
						widget.setVisible("aiDataItemSlot"..i, true)
					end

					widget.setVisible("buttonScreenRight", true)
					widget.setVisible("buttonScreenLeft", true)
					widget.setText("buttonScreenRight", "CRAFT >")
				else
					resetGUI()
					textTyper.init(cfg.TextData, cfg.TextData.strings.noCustomAIMod, customData.chatterSound or cfg.TextData.sound)
					GUI.talker.emote = "refuse"
				end
			end
		end
	end
end


-----------------------------------------------------------------------------------------------------------------------------------------------------
--	Customizable SAIL compatiability stuff
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Still in a safe enviorment. (Except 'aiDataItemSlotInput')

customData = {}
customDataPromise = nil
customDataInited = false

function aiDataItemSlotInput(wd)
	if noError then
		local status, err = pcall(aiDataItemSlotInputSafe, wd)
		if not status then
			enableFailsafe(err)
		end
	end
end

function aiDataItemSlotInputSafe(wd)
	if customDataInited then
		local mouseItem = player.swapSlotItem()
		if (mouseItem and root.itemConfig(mouseItem).config.category == "A.I. Chip") or not mouseItem then
			local slotItem = widget.itemSlotItem(wd)
			player.setSwapSlotItem(slotItem)
			widget.setItemSlotItem(wd, mouseItem)
			world.sendEntityMessage(pane.sourceEntity(), 'storeData', wd, mouseItem)
		end

		customDataPromise = "pending"
		GUI.talker.frame = 0
		GUI.talker.blinkTimer = 0
		customDataInited = false
	end
end

function customDatainit()
	customDataPromise = "pending"
	-- Disable shit
end

function customDataUpdate()
	if customDataPromise ~= nil then
		retrieveCustomData()
	end
end

function retrieveCustomData()
	if customDataPromise == "pending" then
		customDataPromise = world.sendEntityMessage(pane.sourceEntity(), 'returnData')
	end

	if customDataPromise:succeeded() then
		customData = {}

		local data = customDataPromise:result()
		if data and next(data) then
			for i = 1, 3 do
				local chipItem = data["aiDataItemSlot"..i]
				if chipItem then
					local descriptor = root.itemConfig(chipItem.name)
					if descriptor then
						descriptor = descriptor.config
						if descriptor.category == "A.I. Chip" then
							widget.setItemSlotItem("aiDataItemSlot"..i, chipItem.name)
							customData = util.mergeTable(customData, util.mergeTable(descriptor, chipItem.parameters).aiData)
						end
					else
						-- Remove the chip if it no longer exists
						world.sendEntityMessage(pane.sourceEntity(), 'storeData', "aiDataItemSlot"..i, nil)
					end
				end
			end

			if customData then
				if customData.aiFrames then
					GUI.talker.imagePath = customData.aiFrames
				else
					defaultAI("ai")
				end

				if customData.staticFrames then
					GUI.static.image = "/ai/"..customData.staticFrames
				else
					defaultAI("static")
				end

				widget.setText("windowTitle", customData.title or cfg.GUI.title)
				widget.setText("windowSubtitle", customData.subtitle or cfg.GUI.subtitle)
				widget.setImage("windowIcon", customData.titleIcon or cfg.GUI.titleIcon)
			end
		else
			defaultAI()
		end

		draw()
		customDataInited = true
		-- re-enable shit
	elseif customDataPromise:finished() then
		error("^green;"..cfg.TextData.strings.promiseError.."^reset;")
	else
		return
	end

	customDataPromise = nil
end

function defaultAI(type)
	local defaultData = root.assetJson("/ai/ai.config").species[player.species()]

	if not type or type == "ai" then
		if defaultData then
			GUI.talker.imagePath = (defaultData.aiFrames or "apexAi.png")
		end
	end

	if not type or type == "static" then
		if defaultData then
			GUI.static.image = "/ai/"..(defaultData.staticFrames or "staticApex.png")
		end
	end
end

-- Yup... Straight out of the customizable sail mod
function openAIChipCraft()
	local tempData = root.assetJson("/ai/ai.config")
	local interactData = {
		config = "/interface/windowconfig/craftingmerchant.config",
		paneLayoutOverride = {
			windowtitle = {
				title = tempData.interfaceText.craftingTitle,
				subtitle = tempData.interfaceText.craftingSubtitle,
				icon = { file = tempData.titleIcon }
			},
			lblSchematics = { value = tempData.interfaceText.craftingSchematicsTxt },
			lblProducttitle = { value = tempData.interfaceText.craftingProductTxt },
			btnCraft = { caption = tempData.interfaceText.buttonCraft },
			btnStopCraft = { caption = tempData.interfaceText.buttonStopCraft },
			lblProduct = { value = tempData.interfaceText.craftingMatAvailTxt },
			imgPlayerMoneyIcon = { visible = false },
			lblPlayerMoney = { visible = false }
		},
		filter = { "aichip" }
	}

	player.interact("OpenCraftingInterface", interactData, pane.sourceEntity())
	pane.dismiss()
end

-----------------------------------------------------------------------------------------------------------------------------------------------------
--	FU Crew Stuff
-----------------------------------------------------------------------------------------------------------------------------------------------------

function fuResetGUI()
	widget.setText("switchMissionSecondary", "Secondary")
	widget.setText("switchMissionMain", "Main")
end

function fuButtonCrew()
	widget.setSize("root", {144,118})

	widget.setText("path", "root/sail/ui/crew/active")
	GUI.crewViewing = GUI.crewViewing or "active"
	if GUI.crewViewing == "active" then
		widget.setButtonEnabled("switchMissionSecondary", true)
		widget.setButtonEnabled("switchMissionMain", false)
	else
		widget.setButtonEnabled("switchMissionSecondary", false)
		widget.setButtonEnabled("switchMissionMain", true)
	end
	widget.setVisible("switchMissionSecondary", true)
	widget.setVisible("switchMissionMain", true)
	widget.setText("switchMissionSecondary", "Inactive")
	widget.setText("switchMissionMain", "Active")

	GUI.crewInView = true
end

function fuButtonMissions()
	GUI.crewInView = false
end

function fuSwitchMissionMain()
	if GUI.crewInView then
		resetGUI()

		textTyper.stopSounds(cfg.TextData)

		local listItem = "root.crewList."..widget.addListItem("root.crewList")
		widget.setText(listItem..".name", "Loading Crew...")
		widget.setVisible(listItem..".portraitCanvas", false)
		widget.setVisible(listItem..".pseudobutton", false)
		widget.setVisible(listItem..".background", false)
		widget.setVisible(listItem..".portraitBG", false)

		widget.setVisible("root.text", false)
		widget.setVisible("root.crewList", true)
		widget.setText("path", "root/sail/ui/crew/active")
		widget.setText("buttonScreenRight", "DISMISS")
		widget.setData("buttonScreenRight", nil)

		GUI.talker.emote = "unique"
		GUI.list.viewing = "crew"
		GUI.crewRequestTimer = GUI.crewRequestDelay -- Start the whole crew retrieval process

		cfg.Data.crewPromise = nil
		GUI.crewViewing = "active"

		widget.setSize("root", {144,118})
		widget.setButtonEnabled("switchMissionSecondary", true)
		widget.setButtonEnabled("switchMissionMain", false)
		widget.setVisible("switchMissionSecondary", true)
		widget.setVisible("switchMissionMain", true)
		widget.setText("switchMissionSecondary", "Inactive")
		widget.setText("switchMissionMain", "Active")

		GUI.missionViewing = GUI.previousMissionViewing
	else
		GUI.previousMissionViewing = "main"
	end
end

function fuSwitchMissionSecondary()
	if GUI.crewInView then
		resetGUI()

		textTyper.stopSounds(cfg.TextData)

		local listItem = "root.crewList."..widget.addListItem("root.crewList")
		widget.setText(listItem..".name", "Loading Crew...")
		widget.setVisible(listItem..".portraitCanvas", false)
		widget.setVisible(listItem..".pseudobutton", false)
		widget.setVisible(listItem..".background", false)
		widget.setVisible(listItem..".portraitBG", false)

		widget.setVisible("root.text", false)
		widget.setVisible("root.crewList", true)
		widget.setText("path", "root/sail/ui/crew/inactive")
		widget.setText("buttonScreenRight", "DISMISS")
		widget.setData("buttonScreenRight", nil)

		GUI.talker.emote = "unique"
		GUI.list.viewing = "crew"
		GUI.crewRequestTimer = GUI.crewRequestDelay -- Start the whole crew retrieval process

		cfg.Data.crewPromise = nil
		GUI.crewViewing = "inactive"

		widget.setSize("root", {144,118})
		widget.setButtonEnabled("switchMissionSecondary", false)
		widget.setButtonEnabled("switchMissionMain", true)
		widget.setVisible("switchMissionSecondary", true)
		widget.setVisible("switchMissionMain", true)
		widget.setText("switchMissionSecondary", "Inactive")
		widget.setText("switchMissionMain", "Active")

		GUI.missionViewing = GUI.previousMissionViewing
	else
		GUI.previousMissionViewing = "secondary"
	end
end

function fuCrewViewing()
	if GUI.crewViewing == "inactive" then
		if cfg.Data.crew == "pending" then
			cfg.Data.crew = "pendingInactive"
			cfg.Data.crewPromise = nil
		elseif cfg.Data.crew == "pendingInactive" then
			if cfg.Data.crewPromise == nil then
				cfg.Data.crewPromise = world.sendEntityMessage(player.id(), "returnStoredCompanions")
			elseif cfg.Data.crewPromise:succeeded() then
				widget.setVisible("root.crewList", true)
				cfg.Data.crew = cfg.Data.crewPromise:result()
				cfg.Data.crewPromise = nil
				populateCrewList()
			end
		end
	end
end

function fuDismissConfirm()
	if GUI.crewViewing == "inactive" then
		world.sendEntityMessage(player.id(), 'dismissStoredCompanion', cfg.Data.selectedCrewID)
	end
end

function fuCrewSelectedSafe(crew)
	widget.setText("path", "root/sail/ui/crew/"..GUI.crewViewing.."/"..crew.name)
end

function fuPopulateCrewList()
	if GUI.crewViewing == "inactive" then
		textTyper.init(cfg.TextData, cfg.TextData.strings.noStoredCrew, customData.chatterSound or cfg.TextData.sound)
		if customData.noStoredCrewSpeech then
			textTyper.init(cfg.TextData, customData.noStoredCrewSpeech.text or cfg.Speech.noStoredCrewSpeech.text, customData.chatterSound or cfg.TextData.sound)
			GUI.talker.emote = customData.noStoredCrewSpeech.animation or cfg.Speech.noStoredCrewSpeech.animation
			GUI.talker.speedModifier = customData.noStoredCrewSpeech.speedModifier or cfg.Speech.noStoredCrewSpeech.speedModifier
		else
			textTyper.init(cfg.TextData, cfg.Speech.noStoredCrewSpeech.text, customData.chatterSound or cfg.TextData.sound)
			GUI.talker.emote = cfg.Speech.noStoredCrewSpeech.animation
			GUI.talker.speedModifier = cfg.Speech.noStoredCrewSpeech.speedModifier
		end
	end
end
