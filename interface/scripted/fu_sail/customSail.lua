
require "/scripts/util.lua"
require "/scripts/textTyper.lua"

-----------------------------------------------------------------------------------------------------------------------------------------------------
--	UNSAFE FUNCTIONS
-----------------------------------------------------------------------------------------------------------------------------------------------------
--	These functions behave normally, and are called from the cfg.GUI pane.
--	They serve mostly to call the main functions in a safe enviorment.
--	Do not change anything here unless you need to modify some direct interaction that for some reason can't be done in the safe functions.

cfg = {}
noError = true
errorString = "An error has occured.\n\nPlease report this on the Steam page or Discord server with a log attached.\n\nMeanwhile, you can click any of the buttons to open the vanilla version of SAIL."
-- 'errorString' is overriden by whatever is in 'cfg.TextData.strings.error'

function init()
	local status, err = pcall(initSafe)
	if not status then
		script.setUpdateDelta(0)
		enableFailsafe(err)
	end
	
	if noError then
		local status, err = pcall(customDatainit)
		if not status then
			enableFailsafe(err)
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
--	These functions are running in a safe enviorment - Should one of them run into an error, the cfg.GUI will not freeze and stop working.
--	Instead, any of the buttons (except the close button) will open the vanilla SAIL cfg.GUI so players could continue playing without waiting for a fix.
--	However, this does not prevent stack overflows, or errors that cause crashes. (such as a function expecting a string of an image path, but recieving a non-absolute path, or a path leading to a non-image)

function initSafe()
	cfg = root.assetJson("/interface/scripted/fu_sail/aidata.config")
	errorString = cfg.TextData.strings.error
	
	cfg.GUI.canvas = widget.bindCanvas("aiFaceCanvas")
	cfg.GUI.missionViewing = "main"
	
	buildCurrencyList()
	writerInit(cfg.TextData, cfg.TextData.strings.intro)
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
	
	writerSkip(cfg.TextData, "root.text")
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
	
	cfg.GUI.talker.emote = "talk"
	cfg.GUI.list.viewing = nil
	cfg.GUI.dismissConfirmTimer = 0
	cfg.GUI.talker.frameTimer = 0
	cfg.GUI.talker.frame = 0
end

function updateSafe(dt)
	
	customDataUpdate()
	if not customDataInited then return end
	
	if cfg.GUI.dismissConfirmTimer > 0 then
		cfg.GUI.dismissConfirmTimer = cfg.GUI.dismissConfirmTimer - dt
	else
		widget.setButtonEnabled("buttonScreenRight", true)
	end
	
	if cfg.GUI.crewRequestTimer > 0 then
		cfg.GUI.crewRequestTimer = cfg.GUI.crewRequestTimer - dt
	elseif cfg.GUI.crewRequestTimer > -69 then
		cfg.Data.crew = "pending"
		cfg.GUI.crewRequestTimer = -80085
	end
	
	writerUpdate(cfg.TextData, "root.text", cfg.TextData.sound, cfg.TextData.volume, false)
	
	if cfg.GUI.list.viewing then
		if cfg.GUI.list.updateTimer > 0 then
			cfg.GUI.list.updateTimer = cfg.GUI.list.updateTimer - dt
		else
			cfg.GUI.list.updateTimer = cfg.GUI.list.updateInterval
			
			if cfg.GUI.list.viewing == "currency" then
				populateCurrencyList()
				
			elseif cfg.GUI.list.viewing == "crew" then
				
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
				
			else
				cfg.GUI.list.viewing = nil
			end
		end
	end
	
	-- Animate portrait
	if cfg.TextData.isFinished then
		cfg.GUI.talker.uniqueFrameTimer = cfg.GUI.talker.uniqueFrameTimer
		
		if cfg.GUI.talker.emote == "unique" then
			if cfg.GUI.talker.uniqueFrameTimer > 0 then
				cfg.GUI.talker.uniqueFrameTimer = cfg.GUI.talker.uniqueFrameTimer - dt
			else
				cfg.GUI.talker.frame = (cfg.GUI.talker.frame + 1) % cfg.GUI.talker.uniqueMaxFrames
				cfg.GUI.talker.uniqueFrameTimer = cfg.GUI.talker.uniqueFrameDelay
			end
		elseif cfg.GUI.talker.emote == "blink" then
			if cfg.GUI.talker.blinkTimer > 0 then
				cfg.GUI.talker.blinkTimer = cfg.GUI.talker.blinkTimer - dt
			else
				cfg.GUI.talker.emote ="idle"
				cfg.GUI.talker.blinkTimer = cfg.GUI.talker.blinkDelay
				cfg.GUI.talker.frame = 0
			end
		else
			if cfg.GUI.talker.blinkTimer > 0 then
				cfg.GUI.talker.blinkTimer = cfg.GUI.talker.blinkTimer - dt
			else
				cfg.GUI.talker.emote = "blink"
				cfg.GUI.talker.blinkTimer = cfg.GUI.talker.blinkDuration
				cfg.GUI.talker.frame = nil
			end
		end
	else
		-- Make it blink when its done so it resets to idle animation + look cute while at it
		cfg.GUI.talker.blinkTimer = 0
		cfg.GUI.talker.blinking = false
		
		if cfg.GUI.talker.talkFrameTimer > 0 then
			cfg.GUI.talker.talkFrameTimer = cfg.GUI.talker.talkFrameTimer - dt
		else
			cfg.GUI.talker.talkFrameTimer = cfg.GUI.talker.talkFrameDelay
			if cfg.GUI.talker.emote == "unique" or cfg.GUI.talker.emote == "refuse" then
				cfg.GUI.talker.frame = ((cfg.GUI.talker.frame or 0) + 1) % cfg.GUI.talker.uniqueMaxFrames
			else
				cfg.GUI.talker.frame = ((cfg.GUI.talker.frame or 0) + 1) % cfg.GUI.talker.talkMaxFrames
			end
			cfg.GUI.talker.displayImage = cfg.GUI.talker.imagePath..":"..cfg.GUI.talker.emote.."."..cfg.GUI.talker.frame
		end
	end
	
	-- Animate portrait scan lines
	if cfg.GUI.scanLines.frameTimer > 0 then
		cfg.GUI.scanLines.frameTimer = cfg.GUI.scanLines.frameTimer - dt
	else
		cfg.GUI.scanLines.frame = (cfg.GUI.scanLines.frame + 1) % cfg.GUI.scanLines.maxFrames
		cfg.GUI.scanLines.frameTimer = cfg.GUI.scanLines.frameDelay
	end
	
	-- Animate portrait static
	cfg.GUI.static.frame = (cfg.GUI.static.frame + 1) % cfg.GUI.static.maxFrames
	
	draw()
end

function draw()
	cfg.GUI.canvas:clear()
	
	if cfg.GUI.talker.frame then
		cfg.GUI.canvas:drawImage(cfg.GUI.talker.imagePath..":"..cfg.GUI.talker.emote.."."..cfg.GUI.talker.frame, {0,0})
	else
		cfg.GUI.canvas:drawImage(cfg.GUI.talker.imagePath..":"..cfg.GUI.talker.emote, {0,0})
	end
	
	cfg.GUI.canvas:drawImage(cfg.GUI.static.image..":"..cfg.GUI.static.frame, {0,0}, nil, "#FFFFFF25", false)
	cfg.GUI.canvas:drawImage(cfg.GUI.scanLines.image..":"..cfg.GUI.scanLines.frame, {0,0}, nil, "#FFFFFF90", false)
end

function buttonMainSafe(wd)
	if not customDataInited then return end
	if wd == "buttonMain" then
		resetGUI()
		
		widget.setText("path", "root/sail/ui/overview")
		widget.setVisible("root.currencyList", true)
		widget.setVisible("root.text", false)
		
		cfg.GUI.list.viewing = "currency"
		populateCurrencyList()
		
	elseif wd == "buttonMissions" then
		resetGUI()
		widget.setSize("root", {144,118})
		
		widget.setText("path", "root/sail/ui/missions/main")
		widget.setVisible("switchMissionSecondary", true)
		widget.setVisible("switchMissionMain", true)
		widget.setVisible("root.missionList", true)
		widget.setVisible("root.text", false)
		
		cfg.GUI.missionViewing = cfg.GUI.missionViewing or "main"
		if cfg.GUI.missionViewing == "main" then
			widget.setButtonEnabled("switchMissionSecondary", true)
			widget.setButtonEnabled("switchMissionMain", false)
		else
			widget.setButtonEnabled("switchMissionSecondary", false)
			widget.setButtonEnabled("switchMissionMain", true)
		end
		
		populateMissionList()
		widget.setText("buttonScreenRight", " GO! >")
		
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
		
		cfg.GUI.missionViewing = "main"
		populateMissionList()
		
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
		
		cfg.GUI.missionViewing = "secondary"
		populateMissionList()
		
	elseif wd == "buttonScreenRight" then
		if widget.active("root.missionList") then
			resetGUI()
			
			if cfg.Data.missionWorld then
				player.warp("InstanceWorld:"..cfg.Data.missionWorld, "beam")
				pane.dismiss()
			end
		elseif widget.active("root.crewList") then
			if widget.getData("buttonScreenRight") == "dismissConfirm" then
				world.sendEntityMessage(player.id(), 'dismissCompanion', cfg.Data.selectedCrewID)
				widget.setData("buttonScreenRight", nil)
				buttonMainSafe("buttonCrew")
				widget.clearListItems("root.missionList")
			else
				widget.setData("buttonScreenRight", "dismissConfirm")
				widget.setText("buttonScreenRight", "CONFIRM")
				widget.setButtonEnabled("buttonScreenRight", false)
				cfg.GUI.dismissConfirmTimer = cfg.GUI.dismissConfirmDelay
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
		
		cfg.GUI.talker.emote = "unique"
		cfg.GUI.list.viewing = "crew"
		cfg.GUI.crewRequestTimer = cfg.GUI.crewRequestDelay -- Start the whole crew retrieval process
		
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
		if dat.fu_group then
			if not tbl[dat.fu_group] then
				tbl[dat.fu_group] = {}
			end
			
			table.insert(tbl[dat.fu_group], dat)
			tbl[dat.fu_group][#tbl[dat.fu_group]].currency = cur
		elseif not dat.fu_hidden then
			table.insert(tbl.unsorted, dat)
			tbl.unsorted[#tbl.unsorted].currency = cur
		end
	end
	
	local order = {}
	for _, k in ipairs(cd.money.fu_group_order) do
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
				if dat.fu_secret and player.currency(currency) <= 0 then
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
			if not dat.fu_secret or (dat.fu_secret and player.currency(dat.currency) > 0) then
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
	
	local listItem = ""
	local replays = {}
	local noMissions = true
	
	for i, tbl in ipairs(cfg.Data.missions[cfg.GUI.missionViewing]) do
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
				local dat = root.assetJson("/ai/"..tbl[1]..".aimission")
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
				local dat = root.assetJson("/ai/"..tbl[1]..".aimission")
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
		writerInit(cfg.TextData, cfg.TextData.strings.noMissions)
		cfg.GUI.talker.emote = "refuse"
	end
	
	for _, i in ipairs(replays) do
		local dat = root.assetJson("/ai/"..cfg.Data.missions[cfg.GUI.missionViewing][i][1]..".aimission")
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
		widget.setSize("root", {144,136})
		local listData = widget.getData("root.missionList."..selected)
		if listData then
			local dat = root.assetJson("/ai/"..cfg.Data.missions[cfg.GUI.missionViewing][listData.index][1]..".aimission")
			if dat then
				
				local text = dat.speciesText.default.selectSpeech.text
				if customData.missionsText and customData.missionsText[dat.missionName] and customData.missionsText[dat.missionName].selectSpeech then
					text = customData.missionsText[dat.missionName].selectSpeech.text or text
				end
				
				if customData.missionsText and customData.missionsText[dat.missionName] and customData.missionsText[dat.missionName].selectSpeech then
					cfg.GUI.talker.emote = customData.missionsText[dat.missionName].selectSpeech.animation or "talk"
				end
				
				writerInit(cfg.TextData, text)
				cfg.GUI.talker.emote = "talk"
				widget.setText("path", "root/sail/ui/missions/"..dat.missionName)
				widget.setVisible("switchMissionSecondary", false)
				widget.setVisible("switchMissionMain", false)
				widget.setVisible("buttonScreenRight", true)
				widget.setVisible("buttonScreenLeft", true)
				widget.setVisible("root.missionList", true)
				widget.setVisible("root.text", true)
				widget.clearListItems("root.missionList")
				
				cfg.Data.missionWorld = dat.missionWorld
				
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
			local listItem = ""
			local canvas = nil
			
			for i, tbl in ipairs(cfg.Data.crew) do
				listItem = "root.crewList."..widget.addListItem("root.crewList")
				canvas = widget.bindCanvas(listItem..".portraitCanvas")
				
				for _, portrait in ipairs(tbl.portrait) do
					canvas:drawImage(portrait.image, {-15.5, -19.5})
				end
				
				widget.setText(listItem..".name", tbl.name)
				widget.setData(listItem, { index = i, })
			end
		else
			widget.setVisible("root.text", true)
			writerInit(cfg.TextData, cfg.TextData.strings.noCrew)
			cfg.GUI.talker.emote = "refuse"
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
			
			cfg.GUI.list.viewing = nil
			cfg.GUI.crewRequestTimer = -80085
			
			local crew = cfg.Data.crew[listData.index]
			if crew then
				local text = crew.description.."\n^cyan;> Species:^white; "..crew.config.species.."\n^cyan;> Level:^white; "..crew.config.parameters.level
				writerInit(cfg.TextData, text)

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
		widget.setText(listItem..".name", tbl[2])
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
					writerInit(cfg.TextData, cfg.TextData.strings.customAI)
					
					for i = 1, 3 do
						widget.setVisible("aiDataItemSlot"..i, true)
					end
					
					widget.setVisible("buttonScreenRight", true)
					widget.setVisible("buttonScreenLeft", true)
					widget.setText("buttonScreenRight", "CRAFT >")
				else
					resetGUI()
					writerInit(cfg.TextData, cfg.TextData.strings.noCustomAIMod)
					cfg.GUI.talker.emote = "refuse"
				end
			end
		end
	end
end


-----------------------------------------------------------------------------------------------------------------------------------------------------
--	Customizable SAIL compatiability stuff
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Still in a safe enviorment.

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
		local data = customDataPromise:result()
		if data and next(data) then
			for i = 1, 3 do
				local chipItem = data["aiDataItemSlot"..i]
				if chipItem then
					local descriptor = root.itemConfig(chipItem.name).config
					if descriptor and descriptor.category == "A.I. Chip" then
						widget.setItemSlotItem("aiDataItemSlot"..i, chipItem.name)
						customData = util.mergeTable(customData, util.mergeTable(descriptor, chipItem.parameters).aiData)
					end
				end
			end
			
			if customData then
				if customData.aiFrames then
					cfg.GUI.talker.imagePath = "/ai/"..customData.aiFrames
				else
					defaultAI("ai")
				end
				
				if customData.staticFrames then
					cfg.GUI.static.image = "/ai/"..customData.staticFrames
				else
					defaultAI("static")
				end
			end
		else
			defaultAI()
		end
		
		draw()
		customDataInited = true
		-- re-enable shit
	else
		if not customDataPromise:finished() then return end
	end
	
	customDataPromise = nil
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
		cfg.GUI.talker.frame = 0
		cfg.GUI.talker.blinkTimer = 0
		customDataInited = false
	end
end

function defaultAI(type)
	local defaultData = root.assetJson("/ai/ai.config").species[player.species()]
	
	if not type or type == "ai" then
		if defaultData then
			cfg.GUI.talker.imagePath = "/ai/"..(defaultData.aiFrames or "apexAi.png")
		end
	end
	
	if not type or type == "static" then
		if defaultData then
			cfg.GUI.static.image = "/ai/"..(defaultData.staticFrames or "staticApex.png")
		end
	end
end

-- Yup... Straight out of the customizable sail mod
function openAIChipCraft()
	local tempData = root.assetJson("/ai/ai.config")
	local interactData = {
		config = "/interface/windowconfig/craftingmerchant.config",
		--disableTimer = false,
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