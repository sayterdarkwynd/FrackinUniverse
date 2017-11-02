
GD = {
	-- Total distance between roots of list elements
	questNameSpacing = 17,
	
	-- Number of hidden questNames used to create space for the portrait
	portraitQuestNameCount = 2,
	
	-- string used to identify the hidden labels which make space for the portraits
	portraitSpacingString = "PORTRAITSPACING",
	
	unavailableQuestlineString = "UNVAVAILABLEQUESTLINE",
}

QD = {
	current = { line = nil, quest = nil },
	
	linesOrder = {"tutorial", "test"},
	lines = {
		{ id = "tutorial",	sublines = {"kevin", "nivek"},	        requirements = {},		secret = false },
		{ id = "test",		sublines = {"sumfehg"},			requirements = { "git_gud_2"},	secret = false },
		{ id = "test2",		sublines = {"sumothafehg"},		requirements = { "git_gud_4"},	secret = true },
	},
	
	sublines = {
		-- Tutorial subline
		kevin =			{ "git_gud" },
		nivek =			{ "git_gud_2", "git_gud_3"},
		
		-- Test subline
		sumfehg =		{ "git_gud_4" },
		
		-- Test2 subline
		sumothafehg =	{"git_gud_5" },
	},
	
	strings = {
		instructions = { title = "Corvex Research Task Terminal", description = "To select a task, click on its name on the left window, and relevant information will be displayed here.\n\nTasks also come with a color to represent your progress with them: \n^red;red^reset; : unavailable\n^yellow;yellow^reset; : available\n^cyan;cyan^reset; : in progress\n^green;green^reset; : complete.\n\nThere may be different task branches, which you can access by pressing the big image at the top of the window on the left. More become available as you unlock them." },
		
		questlines = {
			tutorial =		{title = "Tutorial",				description = "lrn 2 play cyka noob blyat"			},
			test =			{title = "Test.",				description = "WHOA! MOAR TESTS!!!11!eleven!!11!"	},
			test2 =			{title = "Test 2: electric boog-a-loo",		description = "nice meme"	},
		},
		
		sublines = {
			kevin = "Kevin",
			nivek = "niveK",
			sumfehg = "Sum-Fehg",
			sumothafehg = "Sum'otha-Fehg",
		}
	}
}

function init()
	questlineButton()
	widget.setText("questTitle",	QD.strings.instructions.title )
	widget.setText("questText",		QD.strings.instructions.description )
	self.questListIDs = {}
end

function instructions()
	if widget.active("questlineList") then
		if self.lastSelected then
			 -- repopulate the list to clear selected
			populateQueslineList()
			self.lastSelected = nil
		end
		
	elseif widget.active("questList") then
		if self.lastSelected then
			 -- repopulate the list to clear selected
			populateQuestList()
			self.lastSelected = nil
		end
	end
	
	widget.setButtonEnabled("questButton", false)
	widget.setText("questTitle",	QD.strings.instructions.title )
	widget.setText("questText",		QD.strings.instructions.description )
end

function update()
	if widget.active("questList") then
		updateQuestList()
	end
end


function updateQuestList()
	for questID, path in pairs(self.questListIDs) do
		local config = root.questConfig(questID)
		if config then
			if player.hasCompletedQuest(questID) then
				widget.setText(path..".questName", tostring(config.title))
				widget.setFontColor(path..".questName", "green")
				
			elseif player.hasQuest(questID) then
				widget.setText(path..".questName", tostring(config.title))
				widget.setFontColor(path..".questName", "yellow")
				
			elseif player.canStartQuest(questID) then
				widget.setText(path..".questName", tostring(config.title))
				widget.setFontColor(path..".questName", "cyan")
		
			else
				if config.secret then
					widget.setText(path..".questName", "???")
					widget.setFontColor(path..".questName", "red")
				else
					widget.setText(path..".questName", tostring(config.title))
					widget.setFontColor(path..".questName", "red")
				end
			end
		else
			widget.setText(path..".questName", "ERROR - Missing config for '"..questID.."'")
			widget.setFontColor(path..".questName", "red")
		end
	end
end

function populateQuestList()
	widget.clearListItems("questList.list")
	self.questListIDs = {}
	local questLine = QD.current.line
	
	for i = 1, 5 do
		widget.setPosition("questList.giverPortrait"..i, {0,0})
		widget.setPosition("questList.giverName"..i, {20,1})
		
		widget.setVisible("questList.giverPortrait"..i, false)
		widget.setVisible("questList.giverName"..i, false)
	end
	
	if questLine then
		for _, lineTbl in ipairs(QD.lines) do
			if lineTbl.id == questLine then
				for sublineNum, subline in ipairs(lineTbl.sublines) do
					for questNum, questID in ipairs(QD.sublines[subline]) do
						if questNum == 1 then
							for j = 1, GD.portraitQuestNameCount do
								local tempPath = "questList.list."..widget.addListItem("questList.list")
								widget.setVisible(tempPath..".questName", false)
								widget.setVisible(tempPath..".bg", false)
								widget.setData(tempPath..".questName", GD.portraitSpacingString)
							end
						end
						
						local path = "questList.list."..widget.addListItem("questList.list")
						widget.setData(path..".questName", questID)
						self.questListIDs[questID] = path
						
						if questNum == #QD.sublines[subline] then
							local portrait = "questList.giverPortrait"..tostring(sublineNum)
							local portraitPos = widget.getPosition(portrait)
							
							local label = "questList.giverName"..tostring(sublineNum)
							local labelPos = widget.getPosition(label)
							
							local yOffset = -20
							
							for i = sublineNum, #lineTbl.sublines do
								yOffset = yOffset + (#QD.sublines[lineTbl.sublines[i]] * GD.questNameSpacing) + (GD.questNameSpacing * GD.portraitQuestNameCount)
							end
							
							portraitPos[2] = portraitPos[2] + yOffset
							labelPos[2] = labelPos[2] + yOffset
							
							widget.setImage(portrait, "/interface/scripted/fu_tutorialQuestList/"..subline..".png")
							widget.setPosition(portrait, portraitPos)
							widget.setVisible(portrait, true)
							
							widget.setText(label, QD.strings.sublines[subline])
							widget.setPosition(label, labelPos)
							widget.setVisible(label, true)
						end
						
						updateQuestList()
					end
				end
			end
		end
	end
end

function questSelected()
	local listItem = widget.getListSelected("questList.list")
	if listItem then
		listItem = "questList.list."..listItem
		local id = widget.getData(listItem..".questName")
		
		if id == GD.portraitSpacingString then
			if self.lastSelected then
				local previousID = string.gsub(self.lastSelected, "questList.list.", "")
				widget.setListSelected("questList.list", previousID)
			end
		else
			widget.setVisible(listItem..".bg", true)
			widget.setImage(listItem..".bg", "/interface/scripted/fu_tutorialQuestList/questBackground.png:selected")
			
			local config = root.questConfig(id)
			if config then
				if player.hasCompletedQuest(id) or player.hasQuest(id) or player.canStartQuest(id) then
					widget.setText("questTitle", tostring(config.title))
					widget.setText("questText", tostring(config.text))
				else
					if config.secret then
						widget.setText("questTitle", tostring("^red;???"))
						widget.setText("questText", "?????")
					else
						widget.setText("questTitle", tostring(config.title).." ^red;[UNAVAILABLE]")
						widget.setText("questText", tostring(config.text))
					end
				end
			else
				widget.setText("questTitle", "^red;ERROR")
				widget.setText("questText", "Missing string table for '"..id.."' questline")
			end
			
			if self.lastSelected and self.lastSelected ~= listItem then
				widget.setImage(self.lastSelected..".bg", "/interface/scripted/fu_tutorialQuestList/questBackground.png:default")
			end
			
			self.lastSelected = listItem
			widget.setButtonEnabled("questButton", true)
		end
	end
end

function questButton()
	if widget.active("questlineList") then
		local path = widget.getListSelected("questlineList.list")
		if path then
			path = "questlineList.list."..widget.getListSelected("questlineList.list")
			local questline = widget.getData(path..".banner")
			
			widget.setImage("questlineBanner", "/interface/scripted/fu_tutorialQuestList/banners/"..questline..".png:default")
			widget.setButtonEnabled("questlineButton", true)
			widget.setButtonEnabled("questButton", false)
			widget.setVisible("questList", true)
			widget.setVisible("questlineList", false)
			widget.setText("questTitle", "Select a quest")
			widget.setText("questText", "")
			
			QD.current.line = questline
			populateQuestList()
		end
	elseif widget.active("questList") then
		local path = widget.getListSelected("questList.list")
		if path then
			path = "questList.list."..widget.getListSelected("questList.list")
			local questID = widget.getData(path..".questName")
			
			if not player.hasCompletedQuest(questID) and player.canStartQuest(questID) then
				player.startQuest(questID)
			end
		end
	else
		widget.setButtonEnabled("questButton", false)
	end
end


function populateQueslineList()
	widget.clearListItems("questlineList.list")
	
	for _, tbl in ipairs(QD.lines) do
		local available = true
		
		if tbl.requirements then
			for _, questID in ipairs(tbl.requirements) do
				if not player.hasCompletedQuest(questID) then
					available = false
					break
				end
			end
		end
		
		if available then
			local path = "questlineList.list."..widget.addListItem("questlineList.list")
			widget.setData(path..".banner", tbl.id)
			widget.setImage(path..".banner", "/interface/scripted/fu_tutorialQuestList/banners/"..tbl.id..".png:default")
		elseif not tbl.secret then
			local path = "questlineList.list."..widget.addListItem("questlineList.list")
			widget.setData(path..".banner", GD.unavailableQuestlineString.."_"..tbl.id)
			widget.setImage(path..".banner", "/interface/scripted/fu_tutorialQuestList/banners/"..tbl.id..".png:unavailable")
		end
	end
end

function questlineSelected()
	local listItem = widget.getListSelected("questlineList.list")
	if listItem then
		listItem = "questlineList.list."..listItem
		local id = widget.getData(listItem..".banner")
		
		if string.find(id, GD.unavailableQuestlineString) then
			id = string.gsub(id, GD.unavailableQuestlineString.."_", "")
			widget.setText("questTitle", id.." ^red;[UNAVAILABLE]")
			widget.setText("questText", tostring(QD.strings.questlines[id].description))
			widget.setButtonEnabled("questButton", false)
		else
			if QD.strings.questlines[id] then
				widget.setText("questTitle", tostring(QD.strings.questlines[id].title))
				widget.setText("questText", tostring(QD.strings.questlines[id].description))
			else
				widget.setText("questTitle", "^red;ERROR")
				widget.setText("questText", "Missing string table for '"..id.."' questline")
			end
			widget.setButtonEnabled("questButton", true)
		end
		
		
		local buttons = {
			base = "/interface/scripted/fu_tutorialQuestList/questlineListOverlay.png:selected",
			hover = "/interface/scripted/fu_tutorialQuestList/questlineListOverlay.png:selectedHover",
		}
		widget.setButtonImages(listItem..".overlay", buttons)
		
		if self.lastSelected and self.lastSelected ~= listItem then
			local lastButtons = {
				base = "/interface/scripted/fu_tutorialQuestList/questlineListOverlay.png:default",
				hover = "/interface/scripted/fu_tutorialQuestList/questlineListOverlay.png:hover",
			}
			widget.setButtonImages(self.lastSelected..".overlay", lastButtons)
		end
		
		self.lastSelected = listItem
	end
end

function questlineButton()
	self.lastSelected = nil
	widget.setImage("questlineBanner", "/assetmissing.png")
	widget.clearListItems("questList.list")
	widget.setText("questButton", "Select")
	
	widget.setButtonEnabled("questlineButton", false)
	widget.setButtonEnabled("questButton", false)
	widget.setVisible("questList", false)
	widget.setVisible("questlineList", true)
	
	widget.setText("questTitle", "Select a questline" )
	widget.setText("questText", "" )
	
	populateQueslineList()
end
