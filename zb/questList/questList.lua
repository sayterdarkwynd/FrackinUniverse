
require("/zb/zb_util.lua")

QD = nil
GD = nil

function init()
	GD = root.assetJson("/zb/questList/questList.config")
	QD = root.assetJson("/zb/questList/data.config")

	for _, file in ipairs(QD.questlineFiles) do
		local temp = root.assetJson(file)
		QD = zbutil.MergeTable(QD, temp)
	end

	QD.current = {line = nil, quest = nil}

	local defaultItemParams = root.assetJson("/items/defaultParameters.config")
	self.defaultMaxStack = defaultItemParams.defaultMaxStack

	questlineButton()
	widget.setText("questTitle",	QD.strings.instructions.title )
	widget.setText("textScrollArea.questText",		QD.strings.instructions.description )
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
	widget.setText("questTitle",	QD.strings.instructions.title )
	widget.setText("textScrollArea.questText",		QD.strings.instructions.description )
end


function populateQueslineList()
	widget.clearListItems("questlineList.list")

	widget.setButtonEnabled("questButton", false)
	widget.setText("questButton", "Select")

	local questlineStatuses = status.statusProperty("fuQuestlinesComplete", "")

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
			widget.setImage(path..".banner", "/zb/questList/banners/"..tbl.id..".png:default")

			if string.find(questlineStatuses, tbl.id..";") then
				widget.setVisible(path..".completeImage", true)
			else
				local complete = true
				for _, subline in ipairs(tbl.sublines) do
					if complete then
						for _, questID in ipairs(QD.sublines[subline]) do
							if not player.hasCompletedQuest(questID) then
								complete = false
								break
							end
						end
					end
				end

				if complete then
					widget.setVisible(path..".completeImage", true)
					questlineStatuses = questlineStatuses..tbl.id..";"
					pane.playSound("/sfx/objects/colonydeed_partyhorn.ogg")

					if tbl.moneyRange then
						if type(tbl.moneyRange) == "table" then
							player.addCurrency("money", math.random(tbl.moneyRange[1], tbl.moneyRange[2]))
						else
							player.addCurrency("money", tbl.moneyRange)
						end
					end

					if tbl.rewards then
						for _, rewardTbl in ipairs(tbl.rewards) do
							local item = root.itemConfig(rewardTbl[1])
							local maxStack = item.config.maxStack or self.defaultMaxStack

							if rewardTbl[2] <= maxStack then
								if rewardTbl[3] then
									player.giveItem({ name = rewardTbl[1], count = rewardTbl[2], parameters = rewardTbl[3]})
								else
									player.giveItem({ name = rewardTbl[1], count = rewardTbl[2]})
								end
							else
								local overflow = rewardTbl[2] % maxStack
								local iterations = math.floor(rewardTbl[2] / maxStack)
								for i = 1, iterations do
									if rewardTbl[3] then
										player.giveItem({ name = rewardTbl[1], count = maxStack, parameters = rewardTbl[3]})
									else
										player.giveItem({ name = rewardTbl[1], count = maxStack})
									end

									if i == iterations and overflow > 0 then
										if rewardTbl[3] then
											player.giveItem({ name = rewardTbl[1], count = overflow, parameters = rewardTbl[3]})
										else
											player.giveItem({ name = rewardTbl[1], count = overflow})
										end
									end
								end
							end
						end
					end
				end
			end
		elseif not tbl.secret then
			local path = "questlineList.list."..widget.addListItem("questlineList.list")
			widget.setData(path..".banner", GD.unavailableQuestlineString.."_"..tbl.id)
			widget.setImage(path..".banner", "/zb/questList/banners/"..tbl.id..".png:unavailable")
		end
	end

	status.setStatusProperty("fuQuestlinesComplete", questlineStatuses)
end

function questlineSelected()
	widget.setPosition("textScrollArea.questText", {0, 0})
	widget.clearListItems("textScrollArea.rewardList")

	local listItem = widget.getListSelected("questlineList.list")
	if listItem then
		listItem = "questlineList.list."..listItem
		local id = widget.getData(listItem..".banner")

		if string.find(id, GD.unavailableQuestlineString) then
			id = string.gsub(id, GD.unavailableQuestlineString.."_", "")
			widget.setText("questTitle", tostring(QD.strings.questlines[id].title))

			local text = "^red;UNAVAILABLE!^reset;\nRequirements:"
			for loc, tbl in ipairs(QD.lines) do
				if tbl.id == id then
					for _, quest in ipairs(QD.lines[loc].requirements) do
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
			if QD.strings.questlines[id] then
				widget.setText("questTitle", tostring(QD.strings.questlines[id].title))
				widget.setText("textScrollArea.questText", tostring(QD.strings.questlines[id].description))
			else
				widget.setText("questTitle", "^red;ERROR")
				widget.setText("textScrollArea.questText", "Missing string table for '"..id.."' questline")
			end
			widget.setButtonEnabled("questButton", true)

			for loc, tbl in ipairs(QD.lines) do
				if tbl.id == id then
					if (QD.lines[loc].moneyRange and QD.lines[loc].moneyRange[2] > 0) or (QD.lines[loc].rewards and #QD.lines[loc].rewards > 0) then
						local path = "textScrollArea.rewardList."..widget.addListItem("textScrollArea.rewardList")
						widget.setVisible(path..".rewardsLabel", true)

						widget.setPosition("textScrollArea.questText", {0, GD.rewardListItemHeight})

						if QD.lines[loc].moneyRange and QD.lines[loc].moneyRange[2] > 0 then
							widget.setVisible(path..".rewardsPixelIcon", true)
							widget.setVisible(path..".rewardsPixels", true)

							if QD.lines[loc].moneyRange[1] == QD.lines[loc].moneyRange[2] then
								widget.setText(path..".rewardsPixels", QD.lines[loc].moneyRange[1])
							else
								widget.setText(path..".rewardsPixels", QD.lines[loc].moneyRange[1].." - "..QD.lines[loc].moneyRange[2])
							end
						end

						if QD.lines[loc].rewards then
							local rewards = {}
							path = ""

							for _, rewardTbl in ipairs(QD.lines[loc].rewards) do
								local item = root.itemConfig(rewardTbl[1])
								local maxStack = item.config.maxStack or self.defaultMaxStack

								if rewardTbl[2] <= maxStack then
									table.insert(rewards, rewardTbl)
								else
									local overflow = rewardTbl[2] % maxStack
									local iterations = math.floor(rewardTbl[2] / maxStack)
									for i = 1, iterations do
										table.insert(rewards, {rewardTbl[1], maxStack, rewardTbl[3]})

										if i == iterations and overflow > 0 then
											table.insert(rewards, {rewardTbl[1], overflow, rewardTbl[3]})
										end
									end
								end
							end

							for count, reward in ipairs(rewards) do
								if count % GD.rewardItemSlotCount == 1 then
									path = "textScrollArea.rewardList."..widget.addListItem("textScrollArea.rewardList")
									widget.setVisible(path..".reward1", true)
									widget.setItemSlotItem(path..".reward1", {name = reward[1], count = reward[2]})

									local textHeigh = widget.getPosition("textScrollArea.questText")
									textHeigh[2] = textHeigh[2] + GD.rewardListItemHeight
									widget.setPosition("textScrollArea.questText", textHeigh)
								else
									widget.setItemSlotItem(path..".reward"..count % GD.rewardItemSlotCount, {name = reward[1], count = reward[2]})
									widget.setVisible(path..".reward"..count % GD.rewardItemSlotCount, true)
								end
							end
						end
						break
					end
				end
			end
		end

		local buttons = {
			base = "/zb/questList/questlineListOverlay.png:selected",
			hover = "/zb/questList/questlineListOverlay.png:selectedHover",
		}
		widget.setButtonImages(listItem..".overlay", buttons)

		if self.lastSelected and self.lastSelected ~= listItem then
			local lastButtons = {
				base = "/zb/questList/questlineListOverlay.png:default",
				hover = "/zb/questList/questlineListOverlay.png:hover",
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
				widget.setImage(path..".status", "/zb/questList/status.png:complete")

			elseif player.hasQuest(questID) then
				widget.setText(path..".questName", tostring(config.title))
				widget.setFontColor(path..".questName", "cyan")
				widget.setImage(path..".status", "/zb/questList/status.png:inProgress")

			elseif player.canStartQuest(questID) then
				widget.setText(path..".questName", tostring(config.title))
				widget.setFontColor(path..".questName", "yellow")
				widget.setImage(path..".status", "/zb/questList/status.png:available")

			else
				if config.secret then
					widget.setText(path..".questName", "???")
					widget.setFontColor(path..".questName", "red")
					widget.setImage(path..".status", "/zb/questList/status.png:secret")
				else
					widget.setText(path..".questName", tostring(config.title))
					widget.setFontColor(path..".questName", "red")
					widget.setImage(path..".status", "/zb/questList/status.png:unavailable")
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

	widget.setButtonEnabled("questButton", false)
	widget.setText("questButton", "Receive")

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
							for _ = 1, GD.portraitQuestNameCount do
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

							widget.setImage(portrait, "/zb/questList/givers/"..subline..".png")
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
	widget.setPosition("textScrollArea.questText", {0, 0})
	widget.clearListItems("textScrollArea.rewardList")

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
			widget.setImage(listItem..".bg", "/zb/questList/questBackground.png:selected")

			local config = root.questConfig(id)
			if config then
				if player.hasCompletedQuest(id) then
					widget.setText("questTitle", tostring(config.title))
					widget.setText("textScrollArea.questText", tostring(config.text))
					widget.setButtonEnabled("questButton", false)
				elseif player.canStartQuest(id) or player.hasQuest(id) then
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
						for _, quest in ipairs(config.prerequisites) do
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
					if (config.moneyRange and config.moneyRange[2] > 0) or (config.rewards and #config.rewards > 0) then
						local path = "textScrollArea.rewardList."..widget.addListItem("textScrollArea.rewardList")
						widget.setVisible(path..".rewardsLabel", true)

						widget.setPosition("textScrollArea.questText", {0, GD.rewardListItemHeight})

						if config.moneyRange and config.moneyRange[2] > 0 then
							widget.setVisible(path..".rewardsPixelIcon", true)
							widget.setVisible(path..".rewardsPixels", true)

							if config.moneyRange[1] == config.moneyRange[2] then
								widget.setText(path..".rewardsPixels", config.moneyRange[1])
							else
								widget.setText(path..".rewardsPixels", config.moneyRange[1].." - "..config.moneyRange[2])
							end
						end

						if config.rewards and config.rewards[1] then
							path = ""
							for count, rewardTbl in pairs(config.rewards[1]) do
								if count % GD.rewardItemSlotCount == 1 then
									path = "textScrollArea.rewardList."..widget.addListItem("textScrollArea.rewardList")
									widget.setVisible(path..".reward1", true)
									widget.setItemSlotItem(path..".reward1", {name = rewardTbl[1], count = rewardTbl[2]})

									local textHeigh = widget.getPosition("textScrollArea.questText")
									textHeigh[2] = textHeigh[2] + GD.rewardListItemHeight
									widget.setPosition("textScrollArea.questText", textHeigh)
								else
									widget.setItemSlotItem(path..".reward"..count % GD.rewardItemSlotCount, {name = rewardTbl[1], count = rewardTbl[2]})
									widget.setVisible(path..".reward"..count % GD.rewardItemSlotCount, true)
								end
							end
						end
					end
				end
			else
				widget.setText("questTitle", "^red;ERROR")
				widget.setText("textScrollArea.questText", "Missing string table for '"..id.."' questline")
			end

			if self.lastSelected and self.lastSelected ~= listItem then
				widget.setImage(self.lastSelected..".bg", "/zb/questList/questBackground.png:default")
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

			widget.setImage("questlineBanner", "/zb/questList/banners/"..questline..".png:default")
			widget.setButtonEnabled("questlineButton", true)
			widget.setButtonEnabled("questButton", false)
			widget.setVisible("questList", true)
			widget.setVisible("questlineList", false)
			widget.setText("questTitle", "Select a quest")
			widget.setText("textScrollArea.questText", "")

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
