function init()
	self.GD = root.assetJson("/interface/scripted/fu_tutorialQuestList/fu_tutorialQuestList.config")
	self.QD = root.assetJson("/interface/scripted/fu_tutorialQuestList/questData.config")
	
	questlineButton()
	widget.setText("questTitle",	self.QD.strings.instructions.title )
	widget.setText("textScrollArea.questText",		self.QD.strings.instructions.description )
	self.questListIDs = {}
end

function update()
	if widget.active("questList") then
		updateQuestList()
	end
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
	
	widget.clearListItems("textScrollArea.rewardList")
	widget.setPosition("textScrollArea.questText", {0, 0})
	widget.setButtonEnabled("questButton", false)
	widget.setText("questTitle",	self.QD.strings.instructions.title )
	widget.setText("textScrollArea.questText",		self.QD.strings.instructions.description )
end


function populateQueslineList()
	widget.clearListItems("questlineList.list")
	
	widget.setButtonEnabled("questButton", false)
	widget.setText("questButton", "Select")
	
	for _, tbl in ipairs(self.QD.lines) do
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
			
			if status.resource("fuQueslineComplet_"..tbl.id) > 0 then
				widget.setVisible(path..".completeImage", true)
			else
				local complete = true
				for _, subline in ipairs(tbl.sublines) do
					if complete then
						for _, questID in ipairs(self.QD.sublines[subline]) do
							if not player.hasCompletedQuest(questID) then
								complete = false
								break
							end
						end
					end
				end
				
				if complete then
					widget.setVisible(path..".completeImage", true)
					status.setResource("fuQueslineComplet_"..tbl.id, 1)
					pane.playSound("/sfx/objects/colonydeed_partyhorn.ogg")
					
					if tbl.moneyRange then
						player.addCurrency("money", math.random(tbl.moneyRange[1], tbl.moneyRange[2]))
					end
					
					if tbl.rewards then
						for _, rewardTbl in ipairs(tbl.rewards) do
							player.giveItem({ name = rewardTbl[1], count = rewardTbl[2] })
						end
					end
				end
			end
		elseif not tbl.secret then
			local path = "questlineList.list."..widget.addListItem("questlineList.list")
			widget.setData(path..".banner", self.GD.unavailableQuestlineString.."_"..tbl.id)
			widget.setImage(path..".banner", "/interface/scripted/fu_tutorialQuestList/banners/"..tbl.id..".png:unavailable")
		end
	end
end

function questlineSelected()
	widget.setPosition("textScrollArea.questText", {0, 0})
	widget.clearListItems("textScrollArea.rewardList")
	
	local listItem = widget.getListSelected("questlineList.list")
	if listItem then
		listItem = "questlineList.list."..listItem
		local id = widget.getData(listItem..".banner")
		
		if string.find(id, self.GD.unavailableQuestlineString) then
			id = string.gsub(id, self.GD.unavailableQuestlineString.."_", "")
			widget.setText("questTitle", tostring(self.QD.strings.questlines[id].title))
			
			local text = "^red;UNAVAILABLE!^reset;\nRequirements:"
			for loc, tbl in ipairs(self.QD.lines) do
				if tbl.id == id then
					for _, quest in ipairs(self.QD.lines[loc].requirements) do
						local tempConfig = root.questConfig(quest)
						
						if player.hasCompletedQuest(quest) then
							text = text.."\n - ^green;"..tempConfig.title.."^reset;"
						elseif player.hasQuest(quest) then
							text = text.."\n - ^cyan;"..tempConfig.title.."^reset;"
						elseif player.canStartQuest(quest) then
							text = text.."\n - ^yellow;"..tempConfig.title.."^reset;"
						else
							if tempConfig.secret then
								text = text.."\n - ^red;???^reset;"
							else
								text = text.."\n - ^red;"..tempConfig.title.."^reset;"
							end
						end
					end
					break
				end
			end
			
			widget.setText("textScrollArea.questText", text)
			widget.setButtonEnabled("questButton", false)
		else
			if self.QD.strings.questlines[id] then
				widget.setText("questTitle", tostring(self.QD.strings.questlines[id].title))
				widget.setText("textScrollArea.questText", tostring(self.QD.strings.questlines[id].description))
			else
				widget.setText("questTitle", "^red;ERROR")
				widget.setText("textScrollArea.questText", "Missing string table for '"..id.."' questline")
			end
			widget.setButtonEnabled("questButton", true)
			
			for loc, tbl in ipairs(self.QD.lines) do
				if tbl.id == id then
				
					local path = "textScrollArea.rewardList."..widget.addListItem("textScrollArea.rewardList")
					widget.setVisible(path..".rewardsLabel", true)
					widget.setVisible(path..".rewardsPixelIcon", true)
					widget.setVisible(path..".rewardsPixels", true)
					
					widget.setPosition("textScrollArea.questText", {0, self.GD.rewardListItemHeight})
					
					if self.QD.lines[loc].moneyRange then
						if self.QD.lines[loc].moneyRange[1] == self.QD.lines[loc].moneyRange[2] then
							widget.setText(path..".rewardsPixels", self.QD.lines[loc].moneyRange[1])
						else
							widget.setText(path..".rewardsPixels", self.QD.lines[loc].moneyRange[1].." - "..self.QD.lines[loc].moneyRange[2])
						end
					else
						widget.setText(path..".rewardsPixels", "0")
					end
					
					if self.QD.lines[loc].rewards then
						path = ""
						for count, reward in ipairs(self.QD.lines[loc].rewards) do
							if count % self.GD.rewardItemSlotCount == 1 then
								path = "textScrollArea.rewardList."..widget.addListItem("textScrollArea.rewardList")
								widget.setVisible(path..".reward1", true)
								widget.setItemSlotItem(path..".reward1", {name = reward[1], count = reward[2]})
								
								local textHeigh = widget.getPosition("textScrollArea.questText")
								textHeigh[2] = textHeigh[2] + self.GD.rewardListItemHeight
								widget.setPosition("textScrollArea.questText", textHeigh)
							else
								widget.setItemSlotItem(path..".reward"..count % self.GD.rewardItemSlotCount, {name = reward[1], count = reward[2]})
								widget.setVisible(path..".reward"..count % self.GD.rewardItemSlotCount, true)
							end
						end
					end
					break
				end
			end
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
	widget.setText("textScrollArea.questText", "" )
	
	populateQueslineList()
end


function updateQuestList()
	for questID, path in pairs(self.questListIDs) do
		local config = root.questConfig(questID)
		if config then
			if player.hasCompletedQuest(questID) then
				widget.setText(path..".questName", tostring(config.title))
				widget.setFontColor(path..".questName", "green")
				widget.setImage(path..".status", "/interface/scripted/fu_tutorialQuestList/status.png:complete")
				
			elseif player.hasQuest(questID) then
				widget.setText(path..".questName", tostring(config.title))
				widget.setFontColor(path..".questName", "cyan")
				widget.setImage(path..".status", "/interface/scripted/fu_tutorialQuestList/status.png:inProgress")
				
			elseif player.canStartQuest(questID) then
				widget.setText(path..".questName", tostring(config.title))
				widget.setFontColor(path..".questName", "yellow")
				widget.setImage(path..".status", "/interface/scripted/fu_tutorialQuestList/status.png:available")
		
			else
				if config.secret then
					widget.setText(path..".questName", "???")
					widget.setFontColor(path..".questName", "red")
					widget.setImage(path..".status", "/interface/scripted/fu_tutorialQuestList/status.png:secret")
				else
					widget.setText(path..".questName", tostring(config.title))
					widget.setFontColor(path..".questName", "red")
					widget.setImage(path..".status", "/interface/scripted/fu_tutorialQuestList/status.png:unavailable")
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
	local questLine = self.QD.current.line
	
	widget.setButtonEnabled("questButton", false)
	widget.setText("questButton", "Receive")
	
	for i = 1, 5 do
		widget.setPosition("questList.giverPortrait"..i, {0,0})
		widget.setPosition("questList.giverName"..i, {20,1})
		
		widget.setVisible("questList.giverPortrait"..i, false)
		widget.setVisible("questList.giverName"..i, false)
	end
	
	if questLine then
		for _, lineTbl in ipairs(self.QD.lines) do
			if lineTbl.id == questLine then
				for sublineNum, subline in ipairs(lineTbl.sublines) do
					for questNum, questID in ipairs(self.QD.sublines[subline]) do
						if questNum == 1 then
							for j = 1, self.GD.portraitQuestNameCount do
								local tempPath = "questList.list."..widget.addListItem("questList.list")
								widget.setVisible(tempPath..".questName", false)
								widget.setVisible(tempPath..".bg", false)
								widget.setData(tempPath..".questName", self.GD.portraitSpacingString)
							end
						end
						
						local path = "questList.list."..widget.addListItem("questList.list")
						widget.setData(path..".questName", questID)
						self.questListIDs[questID] = path
						
						if questNum == #self.QD.sublines[subline] then
							local portrait = "questList.giverPortrait"..tostring(sublineNum)
							local portraitPos = widget.getPosition(portrait)
							
							local label = "questList.giverName"..tostring(sublineNum)
							local labelPos = widget.getPosition(label)
							
							local yOffset = -20
							
							for i = sublineNum, #lineTbl.sublines do
								yOffset = yOffset + (#self.QD.sublines[lineTbl.sublines[i]] * self.GD.questNameSpacing) + (self.GD.questNameSpacing * self.GD.portraitQuestNameCount)
							end
							
							portraitPos[2] = portraitPos[2] + yOffset
							labelPos[2] = labelPos[2] + yOffset
							
							widget.setImage(portrait, "/interface/scripted/fu_tutorialQuestList/givers/"..subline..".png")
							widget.setPosition(portrait, portraitPos)
							widget.setVisible(portrait, true)
							
							widget.setText(label, self.QD.strings.sublines[subline])
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
	widget.setPosition("textScrollArea.questText", {0, 0})
	widget.clearListItems("textScrollArea.rewardList")
	
	local listItem = widget.getListSelected("questList.list")
	if listItem then
		listItem = "questList.list."..listItem
		local id = widget.getData(listItem..".questName")
		
		if id == self.GD.portraitSpacingString then
			if self.lastSelected then
				local previousID = string.gsub(self.lastSelected, "questList.list.", "")
				widget.setListSelected("questList.list", previousID)
			end
		else
			widget.setVisible(listItem..".bg", true)
			widget.setImage(listItem..".bg", "/interface/scripted/fu_tutorialQuestList/questBackground.png:selected")
			
			local config = root.questConfig(id)
			if config then
				if player.hasCompletedQuest(id) then
					widget.setText("questTitle", tostring(config.title))
					widget.setText("textScrollArea.questText", tostring(config.text))
					widget.setButtonEnabled("questButton", false)
				elseif player.canStartQuest(id) then
					widget.setText("questTitle", tostring(config.title))
					widget.setText("textScrollArea.questText", tostring(config.text))
					widget.setButtonEnabled("questButton", true)
				else
					if config.secret then
						widget.setText("questTitle", "^red;???")
						widget.setText("textScrollArea.questText", "?????")
					else
						widget.setText("questTitle", tostring(config.title))
						
						local text = "^red;UNAVAILABLE!^reset;\nRequirements:"
						for i, quest in ipairs(config.prerequisites) do
							local tempConfig = root.questConfig(quest)
							
							if player.hasCompletedQuest(quest) then
								text = text.."\n - ^green;"..tempConfig.title.."^reset;"
							elseif player.hasQuest(quest) then
								text = text.."\n - ^cyan;"..tempConfig.title.."^reset;"
							elseif player.canStartQuest(quest) then
								text = text.."\n - ^yellow;"..tempConfig.title.."^reset;"
							else
								if tempConfig.secret then
									text = text.."\n - ^red;???^reset;"
								else
									text = text.."\n - ^red;"..tempConfig.title.."^reset;"
								end
							end
						end
						
						widget.setText("textScrollArea.questText", text)
					end
					widget.setButtonEnabled("questButton", false)
				end
				
				if player.hasCompletedQuest(id) or player.hasQuest(id) or player.canStartQuest(id) then
					
					local path = "textScrollArea.rewardList."..widget.addListItem("textScrollArea.rewardList")
					widget.setVisible(path..".rewardsLabel", true)
					widget.setVisible(path..".rewardsPixelIcon", true)
					widget.setVisible(path..".rewardsPixels", true)
					
					widget.setPosition("textScrollArea.questText", {0, self.GD.rewardListItemHeight})
					
					if config.moneyRange then
						if config.moneyRange[1] == config.moneyRange[2] then
							widget.setText(path..".rewardsPixels", config.moneyRange[1])
						else
							widget.setText(path..".rewardsPixels", config.moneyRange[1].." - "..config.moneyRange[2])
						end
					else
						widget.setText(path..".rewardsPixels", "0")
					end
					
					if config.rewards and config.rewards[1] then
						path = ""
						for count, rewardTbl in pairs(config.rewards[1]) do
							if count % self.GD.rewardItemSlotCount == 1 then
								path = "textScrollArea.rewardList."..widget.addListItem("textScrollArea.rewardList")
								widget.setVisible(path..".reward1", true)
								widget.setItemSlotItem(path..".reward1", {name = rewardTbl[1], count = rewardTbl[2]})
								
								local textHeigh = widget.getPosition("textScrollArea.questText")
								textHeigh[2] = textHeigh[2] + self.GD.rewardListItemHeight
								widget.setPosition("textScrollArea.questText", textHeigh)
							else
								widget.setItemSlotItem(path..".reward"..count % self.GD.rewardItemSlotCount, {name = rewardTbl[1], count = rewardTbl[2]})
								widget.setVisible(path..".reward"..count % self.GD.rewardItemSlotCount, true)
							end
						end
					end
				end
			else
				widget.setText("questTitle", "^red;ERROR")
				widget.setText("textScrollArea.questText", "Missing string table for '"..id.."' questline")
			end
			
			if self.lastSelected and self.lastSelected ~= listItem then
				widget.setImage(self.lastSelected..".bg", "/interface/scripted/fu_tutorialQuestList/questBackground.png:default")
			end
			
			self.lastSelected = listItem
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
			widget.setText("textScrollArea.questText", "")
			
			self.QD.current.line = questline
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

