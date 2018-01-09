
require "/scripts/textTyper.lua"

function init()
	self.data = root.assetJson("/interface/scripted/spaceStation/spaceStation.config")
	stationData = root.assetJson("/interface/scripted/spaceStation/spaceStationData.config")
	questData = stationData.quests
	textData = root.assetJson("/interface/scripted/spaceStation/texts.config")
	dialogueCanvas = widget.bindCanvas("dialogueCanvas")
	
	-- checkShopIntegrity()
	
	shopListIDs = {}
	goodsListIDs = {}
	scientificUpdateDelay = 0
	textUpdateDelay = 0
	shopUpdateDelay = 0
	initialized = false
	objectData = nil
	objectID = nil
	stationType = ""
	
	-- Find closest object and use it
	-- There should only be one object in the stations world anyways
	-- If theres another one close enough to interact with, but the first one is closer to the player
	-- the ones that closer will be read.
	-- So don't do that
	local objects = {}
	local playerPos = world.entityPosition(player.id())
	
	local objectIDs = world.objectQuery(playerPos, 3000, { order = "nearest", name = "spacestationguiconsole" })
	for _, ID in ipairs(objectIDs) do
		local distance = world.distance(world.entityPosition(player.id()), world.entityPosition(ID))
		distance = math.sqrt(distance[1]^2 + distance[2]^2)
		table.insert(objects, {ID, distance})
		break
	end
	
	for _, type in ipairs(stationData.stationTypes) do
		objectIDs = world.objectQuery(playerPos, 3000, { order = "nearest", name = "spacestationguiconsole_"..type })
		for _, ID in ipairs(objectIDs) do
			local distance = world.distance(world.entityPosition(player.id()), world.entityPosition(ID))
			distance = math.sqrt(distance[1]^2 + distance[2]^2)
			table.insert(objects, {ID, distance, type})
			break
		end
	end
	
	local closest = objects[1]
	for _, tbl in ipairs(objects) do 
		if tbl[2] < closest[2] then
			closest = tbl
		end
	end
	
	if closest and closest[1] then
		objectID = closest[1]
		objectData = world.sendEntityMessage(objectID, 'getStorage')
		world.sendEntityMessage(objectID, 'setInteractable', false)
		
		if closest[3] then
			stationType = closest[3]
		end
		
		widget.setText("text", "") -- Clear error message
	else
		widget.setText("text", "ERROR - No station object found")
	end
end

function firstTimeInit()
	sb.logInfo("----------")
	sb.logInfo("STATION OBJECT ID "..objectID.." CALLED FOR THE FIRST TIME. ATTEMPTING TO ADD STATION DATA...")
	objectData = stationData.objectData
	
	--		TEMPORARY - Scientific stations are random instead		--
	------------------------------------------------------------------
		while stationType == "scientific" do
			stationType = stationData.stationTypes[math.random(1,#stationData.stationTypes)]
		end
	------------------------------------------------------------------
	
	
	objectData.stationType = stationType
	
	-- Set type/race if it wasn't set already
	if objectData.stationType == "" then
		objectData.stationType = stationData.stationTypes[math.random(1,#stationData.stationTypes)]
	end
	sb.logInfo("Station type - %s", objectData.stationType)
	
	if objectData.stationRace == "" then
		objectData.stationRace = stationData.stationRaces[math.random(1,#stationData.stationRaces)]
	end
	sb.logInfo("Station race - %s", objectData.stationRace)
	
	-- Set race to generic if chosen one has no texts
	if not textData[objectData.stationRace] then
		sb.logInfo("ERROR - '%s' race is missing textData! Reverting to 'generic'", objectData.stationRace)
		objectData.stationRace = "generic"
	end
	
	objectData.lastVisit = world.time()
	sb.logInfo("Happened at worldtime %s", objectData.lastVisit)
	
	sb.logInfo("----------")
	
	-- Choose what items the station has in its shop
	shopRestock()
	
	-- Generate data based on station type
	if objectData.stationType == "scientific" then
		local tradesAvailable = math.random(stationData.specialsAmountRanges.scientific.min, stationData.specialsAmountRanges.scientific.max)
		local available = {
			common = {},
			uncommon = {},
			rare = {}
		}
		
		for rarity, tbl in pairs(available) do
			for i = 1, #stationData.scientific.outputs[rarity] do
				table.insert(tbl, i)
			end
		end
		
		for i = 1, tradesAvailable do
			local tradeTbl = {}
			
			local rnd = math.random()
			local rarity = "common"
			if rnd <= stationData.scientific.data.chanceUncommon then
				rarity = "uncommon"
			elseif rnd <= stationData.scientific.data.chanceRare then
				rarity = "rare"
			end
			
			for _, tbl in pairs(available) do
				if #available[rarity] < 1 then
					if rarity == "rare" then
						rarity = "uncommon"
						rarityChanges = rarityChanges + 1
						
					elseif rarity == "uncommon" then
						rarity = "common"
						rarityChanges = rarityChanges + 1
						
					elseif rarity == "common" then
						rarity = "rare"
						rarityChanges = rarityChanges + 1
						
					else
						rarity = "common"
						rarityChanges = rarityChanges + 1
					end
				else
					break
				end
			end
			
			if #available[rarity] < 1 then break end
			local indexPosition = math.random(1, #available[rarity])
			local outputIndex = available[rarity][indexPosition]
			
			tradeTbl.stock = math.random(stationData.scientific.data.minStock, stationData.scientific.data.maxStock)
			tradeTbl.input = stationData.scientific.inputs[math.random(1, #stationData.scientific.inputs)]
			tradeTbl.output = stationData.scientific.outputs[rarity][outputIndex]
			tradeTbl.inputRequired = 1
			tradeTbl.outputCount = 1
			
			local itemPrice = math.max(root.itemConfig(tradeTbl.input).config.price or 1, 1)
			local outputPrice = stationData.scientific.data[rarity.."Cost"]
			
			if itemPrice > outputPrice then
				tradeTbl.outputCount = math.ceil(itemPrice / stationData.scientific.data[rarity.."Cost"])
				tradeTbl.stock = math.ceil(tradeTbl.stock / tradeTbl.outputCount)
			elseif itemPrice < outputPrice then
				tradeTbl.inputRequired = math.ceil(stationData.scientific.data[rarity.."Cost"] / itemPrice)
			end
			
			table.remove(available[rarity], indexPosition)
			table.insert(objectData.specialsTable, tradeTbl)
		end
		
		--[[
		-- Uncomment this block to get a list of items in the science specials input list that are below the given price threshold
		-- Also returns any duplicates if there are any
		sb.logInfo("")
		local priceThreshold = 0
		local checked = {}
		local dupes = {}
		
		for _, itemName in ipairs(stationData.scientific.inputs) do
			local item = root.itemConfig(itemName).config
			if not item.price or item.price <= priceThreshold then
				sb.logInfo("%s - %s", itemName, item.price)
			end
			
			for _, name in ipairs(checked) do
				if name == itemName then
					table.insert(dupes, name)
					break
				end
			end
			
			table.insert(checked, itemName)
		end
		
		sb.logInfo("")
		sb.logInfo("")
		sb.logInfo("Dupes:")
		sb.logInfo("")
		for _, name in ipairs(dupes) do
			sb.logInfo("%s", name)
		end
		
		script.setUpdateDelta(0)
		if true then return end
		]]
		
	elseif objectData.stationType == "trading" then
		objectData.specialsTable = {
			invested = 0,
			investing = 0,
			investRequired = 100,
			investLevel = 1
		}
	else
		local specialsAmount = math.random(stationData.specialsAmountRanges[objectData.stationType].min, (stationData.specialsAmountRanges[objectData.stationType].max))
		objectData.specialsTable = getRandomTableIndexes(stationData[objectData.stationType], specialsAmount)
	end
	
	-- Fill the stations trading goods stocks
	for goods, tbl in pairs(stationData.goods) do
		local stock = tbl.baseAmount
		
		local stockStatus = 0 -- -1 = lacking, 0 = normal, 1 = abundance
		if tbl.lack then
			if type(tbl.lack) == "table" then
				for _, type in ipairs(tbl.lack) do
					if type == objectData.stationType then
						stockStatus = stockStatus - 1
						break
					end
				end
			elseif tbl.lack == objectData.stationType then
				stockStatus = stockStatus - 1
			end
		end
		
		if tbl.abundance then
			if type(tbl.abundance) == "table" then
				for _, type in ipairs(tbl.abundance) do
					if type == objectData.stationType then
						stockStatus = stockStatus + 1
						break
					end
				end
			elseif tbl.abundance == objectData.stationType then
				stockStatus = stockStatus + 1
			end
		end
		
		local amountMultiplier = 0
		if stockStatus > 0 then
			local minimum = math.floor(stationData.goodsAbundanceRange[1]*100)
			local maximum = math.floor(stationData.goodsAbundanceRange[2]*100)
			amountMultiplier = math.random(minimum, maximum) * 0.01
		elseif stockStatus < 0 then
			local minimum = math.floor(stationData.goodsLackRange[1]*100)
			local maximum = math.floor(stationData.goodsLackRange[2]*100)
			amountMultiplier = math.random(minimum, maximum) * 0.01
		else
			local minimum = math.floor(stationData.goodsNormalRange[1]*100)
			local maximum = math.floor(stationData.goodsNormalRange[2]*100)
			amountMultiplier = math.random(minimum, maximum) * 0.01
		end
		
		stock = closestWhole(stock * amountMultiplier)
		objectData.goodsStock[tbl.name] = stock
	end
	
	initialized = true
	GUIinit()
end

function GUIinit()
	widget.setImage("talkerImage", textData[objectData.stationRace].portraitPath..":talk.0")
	widget.registerMemberCallback("goodsTradeList.itemList", "buyGoods", buyGoods)
	widget.registerMemberCallback("goodsTradeList.itemList", "sellGoods", sellGoods)
	
	-- Use custom chat sound if the chosen race has one
	if textData[objectData.stationRace].sound then
		textData.sound = textData[objectData.stationRace].sound
		textData.volume = textData[objectData.stationRace].volume
		textData.cutoffSound = textData[objectData.stationRace].cutoffSound
	end
	
	-- Update portrait animation values
	textData.talkFrameCooldown = textData[objectData.stationRace].talkTicksPerFrame
	textData.blinkFrameCooldown = textData[objectData.stationRace].blinkTicksPerFrame
	textData.blinkCooldown = textData[objectData.stationRace].blinkCooldownAvg * (0.5 + math.random())
	
	if objectData.stationType == "trading" then
		widget.setText("investAmount", "")
		widget.setText("investLevel", objectData.specialsTable.investLevel)
		
	elseif objectData.stationType == "scientific" then
		widget.registerMemberCallback("scientificSpecialList.itemList", "tradeA", tradeA)
		widget.registerMemberCallback("scientificSpecialList.itemList", "tradeB", tradeB)
	end
	
	if not objectData.stationName or objectData.stationName == "" then
		local name = ""
		for i, nameTable in ipairs(stationData.naming) do
			local str = nameTable[math.random(1, #nameTable)]
			if i == 1 then
				name = name..str
			else
				if str ~= "" then
					name = name.." "..str
				end
			end
		end
		objectData.stationName = name
	end
	
	local welcomeMessage = string.gsub(textData[objectData.stationRace].welcome, "{STATIONNAME}", "^orange;"..objectData.stationName.."^reset;")
	welcomeMessage = welcomeMessage.."\n\n"..textData[objectData.stationRace][objectData.stationType.."Special"]
	
	writerInit(textData, welcomeMessage)
	resetGUI()
end

function update()
	if not initialized then
		if objectData ~= nil and objectData:finished() then
			if objectData:succeeded() then
				objectData = objectData:result()
				if objectData == nil then
					firstTimeInit()
				else
					GUIinit()
					simulateGoodTrades()
					initialized = true
				end
			end
		end
	else
		if textUpdateDelay == 0 then
			writerUpdate(textData, "text", textData.sound, textData.volume, textData.cutoffSound)
			writerScrambling(textData)
			
			-- Portrait animation
			if textData.textPause <= 0 and not textData.isFinished then
				if textData.talkFrameCooldown <= 0 then
					textData.currentTalkFrame = (textData.currentTalkFrame + 1) % textData[objectData.stationRace].talkTotalFrames
					widget.setImage("talkerImage", textData[objectData.stationRace].portraitPath..":talk."..tostring(textData.currentTalkFrame))
					textData.talkFrameCooldown = textData[objectData.stationRace].talkTicksPerFrame
				else
					textData.talkFrameCooldown = textData.talkFrameCooldown - 1
				end
				
			elseif textData.isFinished then
				if textData.blinkCooldown <= 0 then
					if textData.blinkFrameCooldown <= 0 then
						widget.setImage("talkerImage", textData[objectData.stationRace].portraitPath..":blink."..tostring(textData.currentBlinkFrame))
						
						textData.currentBlinkFrame = textData.currentBlinkFrame + 1
						if textData.currentBlinkFrame >= textData[objectData.stationRace].blinkTotalFrames then
							textData.currentBlinkFrame = textData.currentBlinkFrame % textData[objectData.stationRace].blinkTotalFrames
							textData.blinkCooldown = textData[objectData.stationRace].blinkCooldownAvg * (0.5 + math.random())
						end
						
						textData.blinkFrameCooldown = textData[objectData.stationRace].blinkTicksPerFrame
					else
						textData.blinkFrameCooldown = textData.blinkFrameCooldown - 1
					end
				else
					if textData.blinkFrameCooldown <= 0 then
						widget.setImage("talkerImage", textData[objectData.stationRace].portraitPath..":talk.0")
						textData.blinkCooldown = textData.blinkCooldown - 1
					else
						textData.blinkFrameCooldown = textData.blinkFrameCooldown - 1
					end
				end
			
			else	-- during text pauses
				textData.currentTalkFrame = 0
				widget.setImage("talkerImage", textData[objectData.stationRace].portraitPath..":talk.0")
				textData.talkFrameCooldown = textData[objectData.stationRace].talkTotalFrames
			end
			
			textUpdateDelay = self.data.textDelay - 1
		else
			textUpdateDelay = textUpdateDelay - 1
		end
		
		-- player pixel display update
		if widget.active("playerPixels") then
			widget.setText("playerPixels", "Your pixels: "..tostring(player.currency("money")))
		end
		
		-- Keep updating scietific trades list when its active because player inventory can change (Delayed)
		if widget.active("scientificSpecialList") then
			if scientificUpdateDelay <= 0 then
				checkScientificAvailability()
				scientificUpdateDelay = self.data.scientificUpdateDelay
			else
				scientificUpdateDelay = scientificUpdateDelay - 1
			end
		end
		
		-- Check which items can/cannot be afforded because player pixel balance tends to change in shops for some mysterious reasons.
		if widget.active("shopScrollList") then
			if shopUpdateDelay <= 0 then
				checkShopAvailability()
				shopUpdateDelay = self.data.shopUpdateDelay
			else
				shopUpdateDelay = shopUpdateDelay - 1
			end
		end
		
		if widget.active("goodsTradeList") then
			checkGoodsAvailability()
		end
	end
end

function commandProcessor(wd)
	if not initialized then return end
	
	local command = tostring(widget.getData(wd))
	if command == "Chat" then
		writerInit(textData, textData[objectData.stationRace]["chat"..math.random(1,textData[objectData.stationRace].chatCount)])
		
	elseif command == "Quest" then
		local stage = objectData.currentQuest.stage
		if stage == 0 then	-- Requesting a quest
			updateQuestDetails(objectData.currentQuest.difficulty)
			writerInit(textData, textData[objectData.stationRace]["questStage"..stage].."\n\n"..buildQuestString())
			modifyButtons("Accept", "Easier", "Harder", false, false, "Decline")
			
		elseif stage == 1 then	-- Requesting a quest when there's one in progress
			writerInit(textData, textData[objectData.stationRace]["questStage"..stage])
			resetGUI()
			
		elseif stage == 2 then	-- Returning a failed quest
			objectData.currentQuest.stage = 0
			objectData.currentQuest.difficulty = 1
			writerInit(textData, textData[objectData.stationRace]["questStage"..stage])
			resetGUI()
			
		elseif stage == 3 then	-- Returning a complete quest
			objectData.currentQuest.stage = 0
			-- reward the player
			objectData.currentQuest.current.difficulty = 1
			writerInit(textData, textData[objectData.stationRace]["questStage"..stage])
			resetGUI()
		end
	
	elseif command == "Accept" then
		objectData.currentQuest.stage = 1
		writerInit(textData, textData[objectData.stationRace].questAccept)
		resetGUI()
		
	elseif command == "Decline" then
		objectData.currentQuest.difficulty = 1
		writerInit(textData, textData[objectData.stationRace].questDecline)
		resetGUI()
	
	elseif command == "Easier" then
		-- modify values
		objectData.currentQuest.difficulty = objectData.currentQuest.difficulty - 1
		updateQuestDetails(objectData.currentQuest.difficulty)
		writerInit(textData, textData[objectData.stationRace].questEasier.."\n\n"..buildQuestString())
		
		if objectData.currentQuest.difficulty < 1 then
			modifyButtons("Accept", false, "Harder", false, false, "Decline")
		else
			modifyButtons("Accept", "Easier", "Harder", false, false, "Decline")
		end
	
	elseif command == "Harder" then
		-- modify values
		objectData.currentQuest.difficulty = objectData.currentQuest.difficulty + 1
		updateQuestDetails(objectData.currentQuest.difficulty)
		writerInit(textData, textData[objectData.stationRace].questHarder.."\n\n"..buildQuestString())
		
		if objectData.currentQuest.difficulty > 1 then
			modifyButtons("Accept", "Easier", false, false, false, "Decline")
		else
			modifyButtons("Accept", "Easier", "Harder", false, false, "Decline")
		end
	
	elseif command == "Shop" then
		widget.setVisible("shopScrollList", true)
		widget.setVisible("shopBuyAmountBG", true)
		widget.setVisible("shopBuyAmount", true)
		widget.setVisible("shopBuyButton", true)
		widget.setVisible("shopIncrement", true)
		widget.setVisible("shopDecrement", true)
		widget.setVisible("shopTotalPriceLabel", true)
		widget.setVisible("shopTotalPrice", true)
		widget.setVisible("pixelIcon", true)
		
		widget.setText("shopTotalPrice", "0")
		
		populateShopList()
		writerInit(textData, "")
		widget.setText("text", "")
		modifyButtons("Sell", false, false, false, false, "Back")
		
	elseif command == "Trade Goods" then
		populateGoodsList()
		writerInit(textData, "")
		widget.setText("text", "")
		
		widget.setVisible("playerPixels", true)
		widget.setPosition("playerPixels", self.data.pixelDisplayTradePos)
		modifyButtons(false, false, false, false, false, "Back")
		
	elseif command == "Special" then
		local type = objectData.stationType
		-- writerInit must happen AFTER populating a list
		-- Because if you pick an item on a list, close it, and then re-open it, the game will run the list item selected script
		-- Which ould init the 'no item selected' error message
		
		if type == "military" then
			if objectData.mercHired then
				writerInit(textData, textData[objectData.stationRace].noMoreMerc)
			else
				modifyButtons("Hire Crew", false, false, false, false, "Back")
				widget.setButtonEnabled("button1", false)
				widget.setVisible("specialsScrollList", true)
				populateSpecialList()
				writerInit(textData, textData[objectData.stationRace]["militarySpecial"])
			end
			
		elseif type == "medical" then
			writerInit(textData, "[(instant)^red;Medical station special is temporarily disabled due to player corrupting bugs]")
			
			-- modifyButtons("Acquire", "Remove", false, false, false, "Back")
			-- widget.setButtonEnabled("button1", false)
			
			-- if status.statusProperty("fuMedicalEnhancerDuration", 0) <= 0 then
				-- widget.setButtonEnabled("button2", false)
			-- end
			
			-- local cooldown = math.floor(status.statusProperty("fuMedicalEnhancerCooldown", 0))
			-- if player.isAdmin() then cooldown = 0 end
			
			-- if cooldown == 0 then
				-- widget.setPosition("playerPixels", self.data.pixelDisplaySpecialPos)
				-- widget.setVisible("specialsScrollList", true)
				-- widget.setVisible("playerPixels", true)
				
				-- populateSpecialList()
				-- writerInit(textData, textData[objectData.stationRace]["medicalSpecial"])
			-- else
				-- textData.medicalSpecialCooldownRemaining = toTime(cooldown)
				-- writerInit(textData, textData[objectData.stationRace].cooldownEnhancer)
			-- end
			
		elseif type == "scientific" then
			widget.setVisible("scientificSpecialList", true)
			writerInit(textData, textData[objectData.stationRace].scientificSpecial)
			populateScientificList()
			
			writerInit(textData, textData[objectData.stationRace]["scientificSpecial"])
			modifyButtons(false, false, false, false, false, "Back")
			
		elseif type == "trading" then
			specialsTableInit()
			updateBar(true)
			updateBar(false)
			modifyButtons(false, false, false, false, false, "Back")
		else
			writerInit(textData, "^red;ERROR -^reset;\nWrong 'type' recieved in 'commandProcessor' > 'elseif command == \"Special\" then'")
			resetGUI()
		end
		
	elseif command == "Hire Crew" then
		local merc = stationData.selected
		if merc then
			local price = stationData.military[stationData.selected.index][2]
			if player.consumeCurrency("money", price) then
				world.spawnNpc(world.entityPosition(player.id()), stationData.crewRaces[math.random(1, #stationData.crewRaces)], stationData.military[stationData.selected.index][4], 1, math.random(255), {})
				objectData.mercHired = true
				
				writerInit(textData, textData[objectData.stationRace].hireMerc)
				resetGUI()
			else
				writerInit(textData, textData[objectData.stationRace]["cantAfford"..math.random(1,textData[objectData.stationRace].cantAffordCount)])
			end
		end
		
	elseif command == "Back" then
		writerInit(textData, textData[objectData.stationRace].returnSpecial)
		resetGUI()
		
	elseif command == "Acquire" then
		local special = stationData.selected
		if special then
			
			local price = stationData.medical[stationData.selected.index][2]
			if player.consumeCurrency("money", price) then
				local effect = stationData.medical[stationData.selected.index][4]
				
				status.setStatusProperty("fuMedicalEnhancerDuration", stationData.medical[stationData.selected.index][5])
				status.setStatusProperty("fuMedicalEnhancerCooldown", stationData.medicalSpecialCooldown)
				status.addPersistentEffect("medicalStationSpecials", effect)
				
				writerInit(textData, textData[objectData.stationRace].acquireEnhancer)
				resetGUI()
			else
				writerInit(textData, textData[objectData.stationRace]["cantAfford"..math.random(1,textData[objectData.stationRace].cantAffordCount)])
			end
		end
	
	elseif command == "Remove" then
		if player.consumeCurrency("money", stationData.medicalEnhancerRemoveCost) then
			-- enhancers should handle getting removed by themselves when the resource is 0
			status.setStatusProperty("fuMedicalEnhancerDuration", 0)
			
			widget.setButtonEnabled("button2", false)
			writerInit(textData, textData[objectData.stationRace].removeEnhancer)
		else
			writerInit(textData, textData[objectData.stationRace]["cantAfford"..math.random(1,textData[objectData.stationRace].cantAffordCount)])
		end
	elseif command == "Buy" then
		resetGUI()
		
		widget.setVisible("shopScrollList", true)
		widget.setVisible("shopBuyAmountBG", true)
		widget.setVisible("shopBuyAmount", true)
		widget.setVisible("shopBuyButton", true)
		widget.setVisible("shopIncrement", true)
		widget.setVisible("shopDecrement", true)
		widget.setVisible("shopTotalPriceLabel", true)
		widget.setVisible("shopTotalPrice", true)
		widget.setVisible("pixelIcon", true)
		
		widget.setText("shopTotalPrice", "0")
		
		populateShopList()
		writerInit(textData, "")
		widget.setText("text", "")
		modifyButtons("Sell", false, false, false, false, "Back")
	elseif command == "Sell" then
		resetGUI()
		
		widget.setVisible("shopSellButton", true)
		widget.setVisible("shopTotalPriceLabel", true)
		widget.setVisible("shopTotalPrice", true)
		widget.setVisible("pixelIcon", true)
		
		calculateSellPrice()
		
		for row = 1, self.data.shopSellSlots[1] do
			for column = 1, self.data.shopSellSlots[2] do
				widget.setVisible("shopSellSlot"..row..column, true)
			end
		end
		
		writerInit(textData, "")
		widget.setText("text", "")
		modifyButtons("Buy", false, false, false, false, "Back")
	elseif command == "Goodbye" then
		pane.dismiss()
	end
end

-- Modify buttons based on recieved values
-- {string, string}	- Changes button text to 1st string, and button data to 2nd string
-- string			- Changes the text and data on the button to the recieved string
-- false			- Hides and disables the button
-- nil				- applies no changes
function modifyButtons(b1, b2, b3, b4, b5, b6)
	if b1 then
		widget.setButtonEnabled("button1", true)
		widget.setVisible("button1", true)
		
		if type(b1) == "table" then
			widget.setText("button1", tostring(b1[1]))
			widget.setData("button1", tostring(b1[2]))
		else
			widget.setText("button1", tostring(b1))
			widget.setData("button1", tostring(b1))
		end
	elseif b1 == false then
		widget.setButtonEnabled("button1", false)
		widget.setVisible("button1", false)
	end
	
	if b2 then
		widget.setButtonEnabled("button2", true)
		widget.setVisible("button2", true)
		
		if type(b2) == "table" then
			widget.setText("button2", tostring(b2[1]))
			widget.setData("button2", tostring(b2[2]))
		else
			widget.setText("button2", tostring(b2))
			widget.setData("button2", tostring(b2))
		end
	elseif b2 == false then
		widget.setButtonEnabled("button2", false)
		widget.setVisible("button2", false)
	end
	
	if b3 then
		widget.setButtonEnabled("button3", true)
		widget.setVisible("button3", true)
		
		if type(b3) == "table" then
			widget.setText("button3", tostring(b3[1]))
			widget.setData("button3", tostring(b3[2]))
		else
			widget.setText("button3", tostring(b3))
			widget.setData("button3", tostring(b3))
		end
	elseif b3 == false then
		widget.setButtonEnabled("button3", false)
		widget.setVisible("button3", false)
	end
	
	if b4 then
		widget.setButtonEnabled("button4", true)
		widget.setVisible("button4", true)
		
		if type(b4) == "table" then
			widget.setText("button4", tostring(b4[1]))
			widget.setData("button4", tostring(b4[2]))
		else
			widget.setText("button4", tostring(b4))
			widget.setData("button4", tostring(b4))
		end
	elseif b4 == false then
		widget.setButtonEnabled("button4", false)
		widget.setVisible("button4", false)
	end
	
	if b5 then
		widget.setButtonEnabled("button5", true)
		widget.setVisible("button5", true)
		
		if type(b5) == "table" then
			widget.setText("button5", tostring(b5[1]))
			widget.setData("button5", tostring(b5[2]))
		else
			widget.setText("button5", tostring(b5))
			widget.setData("button5", tostring(b5))
		end
	elseif b5 == false then
		widget.setButtonEnabled("button5", false)
		widget.setVisible("button5", false)
	end
	
	if b6 then
		widget.setButtonEnabled("button6", true)
		widget.setVisible("button6", true)
		
		if type(b6) == "table" then
			widget.setText("button6", tostring(b6[1]))
			widget.setData("button6", tostring(b6[2]))
		else
			widget.setText("button6", tostring(b6))
			widget.setData("button6", tostring(b6))
		end
	elseif b6 == false then
		widget.setButtonEnabled("button6", false)
		widget.setVisible("button6", false)
	end
end

-- Restores GUI to its default states (set default buttons in textData.defaultButtonStates)
function resetGUI()
	local btTbl = textData.defaultButtonStates
	modifyButtons(btTbl[1], btTbl[2], btTbl[3], btTbl[4], btTbl[5], btTbl[6])
	
	widget.setVisible("investEmptyBar", false)
	widget.setVisible("investingFillBar", false)
	widget.setVisible("investFillBar", false)
	widget.setVisible("investLevel", false)
	widget.setVisible("investButton", false)
	widget.setVisible("investMax", false)
	widget.setVisible("investAmountBG", false)
	widget.setVisible("investAmount", false)
	widget.setVisible("investRequired", false)
	widget.setVisible("benefitsLabel", false)
	widget.setVisible("benefitsBuyPriceLabel", false)
	widget.setVisible("benefitsBuyPriceMult", false)
	widget.setVisible("benefitsSellPriceLabel", false)
	widget.setVisible("benefitsSellPriceMult", false)
	
	widget.setVisible("shopScrollList", false)
	widget.setVisible("shopBuyAmount", false)
	widget.setVisible("shopBuyButton", false)
	widget.setVisible("shopIncrement", false)
	widget.setVisible("shopDecrement", false)
	widget.setVisible("shopTotalPriceLabel", false)
	widget.setVisible("shopTotalPrice", false)
	widget.setVisible("pixelIcon", false)
	widget.setVisible("shopBuyAmountBG", false)
	widget.setVisible("specialsScrollList", false)
	widget.setVisible("goodsTradeList", false)
	widget.setVisible("scientificSpecialList", false)
	widget.setVisible("playerPixels", false)
	widget.setVisible("shopSellButton", false)
	
	for row = 1, self.data.shopSellSlots[1] do
		for column = 1, self.data.shopSellSlots[2] do
			widget.setVisible("shopSellSlot"..row..column, false)
		end
	end
	
	stationData.selected = nil
end

-- Update quest text values
function updateQuestDetails(difficulty)
	for loc, data in pairs(questData["dif"..difficulty][math.random(1, #questData["dif"..difficulty])]) do
		objectData.currentQuest[loc] = data
	end
end

-- Return a printable string of the quest details that replaced the placeholders
function buildQuestString()
	local str = textData[objectData.stationRace].questBriefing
	str = string.gsub(str, "{LOCATION}", "^orange;"..tostring(objectData.currentQuest.location).."^reset;")
	str = string.gsub(str, "{OBJECTIVE}", "^orange;"..tostring(objectData.currentQuest.objective).."^reset;")
	str = string.gsub(str, "{TIME}", "^orange;"..tostring(objectData.currentQuest.time).."^reset;")
	str = string.gsub(str, "{REWARD}", "^orange;"..tostring(objectData.currentQuest.reward).."^reset;")
	return str
end

-- Skip text when clicking on dialogue box
function canvasClickEvent(position, button, isButtonDown)
	if isButtonDown then
		writerSkip(textData, "text")
	end
end


--------------------------- SHOP ---------------------------
------------------------------------------------------------

function populateShopList()
	widget.clearListItems("shopScrollList.itemList")
	shopListIDs = {}
	
	for _, item in ipairs(objectData.shopItems) do
		if type(item) == "table" then
			
			local config = root.itemConfig(item.name)
			-- if config then
				local listItem = "shopScrollList.itemList."..widget.addListItem("shopScrollList.itemList")
				local price = math.max((item.parameters.price or config.config.price or 1), 1)
				
				if item.parameters.level then
					price = price * (math.max(item.parameters.level * 0.5, 1))
				end
				price = calculateShopPrice(price, true)
				
				widget.setText(listItem..".name", item.parameters.shortdescription or config.config.shortdescription)
				widget.setItemSlotItem(listItem..".item", item)
				widget.setText(listItem..".price", price)
				widget.setData(listItem, { name = item.name, price = price, maxStack = config.config.maxStack, isWeapon = true })
			-- end
		else
			local config = root.itemConfig(item)
			if config then
				local listItem = "shopScrollList.itemList."..widget.addListItem("shopScrollList.itemList")
				local isWeapon = false
				local basePrice = math.max(config.config.price or 1, 1)
				local maxStack = config.config.maxStack or 1000
				
				local price = calculateShopPrice(basePrice, true)
				
				widget.setText(listItem..".name", config.config.shortdescription)
				widget.setItemSlotItem(listItem..".item", item)
				widget.setText(listItem..".price", price)
				widget.setData(listItem, { name = config.config.itemName, price = price, maxStack = maxStack })
				
				table.insert(shopListIDs, listItem)
			else
				sb.logError("")
				sb.logError("ERROR - Failed to retrieve config for '%s' item from the '%s' shop item pool", item, objectData.stationType)
			end
		end
	end
	
	checkShopAvailability()
	stationData.selected = nil
end

function checkShopAvailability()
	for _, listItem in ipairs(shopListIDs) do
		local data = widget.getData(listItem)
		
		if data.price >= player.currency("money") then
			widget.setVisible(listItem..".unavailableOverlay", true)
			widget.setFontColor(listItem..".price", "red")
		else
			widget.setVisible(listItem..".unavailableOverlay", false)
			widget.setFontColor(listItem..".price", "white")
		end
	end
end

function shopSelected()
	local listItem = widget.getListSelected("shopScrollList.itemList")
	stationData.selected = listItem
	
	if listItem then
		local itemData = widget.getData("shopScrollList.itemList."..listItem)
		stationData.selected = itemData
		
		if player.currency("money") >= itemData.price then
			widget.setText("shopBuyAmount", "x1")
		else
			widget.setText("shopBuyAmount", "x0")
		end
	else
		widget.setText("shopBuyAmount", "x0")
	end
end

function shopBuyAmount(wd)
	if stationData.selected then
		local value = widget.getText(wd)
		local affordable = math.min(math.floor(player.currency("money") / stationData.selected.price), stationData.selected.maxStack)
		
		value = string.gsub(value, "x", "")
		value = tonumber(value)
		
		if not value or value <= 0 then
			if affordable > 0 then
				value = 1
			else
				value = 0
			end
		else
			value = math.min(value, affordable)
		end
		
		widget.setText(wd, value)
		widget.setText("shopTotalPrice", math.floor(value * stationData.selected.price))
	else
		widget.setText(wd, "x0")
		widget.setText("shopTotalPrice", 0)
	end
end

function shopRestock()
	-- Clear table
	local length = #objectData.shopItems
	for i = 1, length do
		table.remove(objectData.shopItems, length - i + 1)
	end
	
	local uniqueAmount = math.random(stationData.shop.minUniqueItems, stationData.shop.maxUniqueItems)
	local genericAmount = math.random(stationData.shop.minGenericItems, stationData.shop.maxGenericItems)
	
	local indexes = getRandomTableIndexes(stationData.shop.potentialStock[objectData.stationType], uniqueAmount)
	for _, i in ipairs(indexes) do
		local item = stationData.shop.potentialStock[objectData.stationType][i]
		if item then
			local config = root.itemConfig(item)
			if config then
				if root.itemHasTag(item, "weapon") then
					local level = 0
					local price = config.config.price or 1
					price = math.max(price, 1)
					
					local roll = math.random(1,100)
					local tiers = stationData.shop.weaponLevelRates
					for i = 1, #tiers do
						if roll < tiers[#tiers - i + 1] then
							level = i
							break
						end
					end
					
					item = root.createItem(item, level)
					
					item.parameters.price = price
				end
				
				table.insert(objectData.shopItems, item)
			end
		else
			logError("ERROR - INVALID ITEM '%s' WAS NOT ADDED TO SHOP", item)
		end
	end
	
	indexes = getRandomTableIndexes(stationData.shop.potentialStock.generic, genericAmount)
	for _, i in ipairs(indexes) do
		local item = stationData.shop.potentialStock.generic[i]
		if item then
			local config = root.itemConfig(item)
			if config then
				if root.itemHasTag(item, "weapon") then
					local level = 0
					local price = config.config.price or 1
					price = math.max(price, 1)
					
					local roll = math.random(1,100)
					local tiers = stationData.shop.weaponLevelRates
					for i = 1, #tiers do
						if roll < tiers[#tiers - i + 1] then
							level = i
							break
						end
					end
					
					item = root.createItem(item, level)
					
					item.parameters.price = price
				end
				
				table.insert(objectData.shopItems, item)
			end
		else
			logError("ERROR - INVALID ITEM '%s' WAS NOT ADDED TO SHOP", item)
		end
	end
end

function shopBuy()
	if stationData.selected then
		local amount = string.gsub(widget.getText("shopBuyAmount"),"x","")
		amount = tonumber(amount)
		if amount and amount > 0 then
			if player.consumeCurrency("money", stationData.selected.price * amount) then
				widget.playSound("/sfx/objects/coinstack_small"..math.random(1,3)..".ogg")
				
				if stationData.selected.isWeapon then
					local slot = widget.getListSelected("shopScrollList.itemList")
					local item = widget.itemSlotItem("shopScrollList.itemList."..slot..".item")
					
					for i = 1, amount do
						player.giveItem(item)
					end
				else
					player.giveItem({ name = stationData.selected.name, count = amount })
				end
			end
		end
	end
	widget.setText("shopBuyAmount", "x0")
	widget.setText("shopTotalPrice", "0")
end

function shopIncrement()
	if stationData.selected then
		local currentValue = string.gsub(widget.getText("shopBuyAmount"),"x","")
		currentValue = tonumber(currentValue)
		local value = currentValue
		local price = 0
		
		if value then
			local affordable = math.min(math.floor(player.currency("money") / stationData.selected.price), stationData.selected.maxStack)
			if value < affordable then
				value = value + 1
			end
		else
			if player.currency("money", stationData.selected.price) then
				value = 1
			else
				value = 0
			end
		end
		
		widget.setText("shopBuyAmount", "x"..value)
		widget.setText("shopTotalPrice", math.floor(value * stationData.selected.price))
	end
end

function shopDecrement()
	if stationData.selected then
		local currentValue = string.gsub(widget.getText("shopBuyAmount"),"x","")
		currentValue = tonumber(currentValue)
		local value = currentValue
		
		if value then
			if value <= 1 then
				value = math.min(math.floor(player.currency("money") / stationData.selected.price), stationData.selected.maxStack)
			else
				value = value - 1
			end
		else
			if player.currency("money", stationData.selected.price) then
				value = 1
			else
				value = 0
			end
		end
		
		widget.setText("shopBuyAmount", "x"..value)
		widget.setText("shopTotalPrice", math.floor(value * stationData.selected.price))
	end
end

function shopItemSlot(wd)
	local slotItem = widget.itemSlotItem(wd)
	local cursorItem = player.swapSlotItem()
	
	if cursorItem and slotItem and cursorItem.name == slotItem.name then
		local slotItemConfig = root.itemConfig(cursorItem.name)
		local maxStack = slotItemConfig.config.maxStack
		if not maxStack then maxStack = 1000 end
		
		if slotItem.count < maxStack then
			local overflow = cursorItem.count + slotItem.count - maxStack
			
			if overflow > 0 then
				cursorItem.count = overflow
				slotItem.count = maxStack
			elseif overflow == 0 then
				cursorItem = nil
				slotItem.count = maxStack
			else
				cursorItem = nil
				slotItem.count = maxStack + overflow
			end
			
			player.setSwapSlotItem(cursorItem)
			widget.setItemSlotItem(wd, slotItem)
		else
			return
		end
	else
		player.setSwapSlotItem(slotItem)
		widget.setItemSlotItem(wd, cursorItem)
	end
	
	calculateSellPrice()
end

function shopItemSlotRight(wd)
	local slotItem = widget.itemSlotItem(wd)
	local cursorItem = player.swapSlotItem()
	
	if slotItem then
		if cursorItem then
			if cursorItem.name == slotItem.name then
				local slotItemConfig = root.itemConfig(cursorItem.name)
				local maxStack = slotItemConfig.config.maxStack
				if not maxStack then maxStack = 1000 end
				
				if cursorItem.count < maxStack then
					player.setSwapSlotItem({name = cursorItem.name, count = cursorItem.count + 1, parameters = cursorItem.parameters})
					if slotItem.count > 1 then
						widget.setItemSlotItem(wd, {name = slotItem.name, count = slotItem.count - 1, parameters = slotItem.parameters})
					else
						widget.setItemSlotItem(wd, nil)
					end
				end
			end
		else
			player.setSwapSlotItem({name = slotItem.name, count = 1, parameters = slotItem.parameters})
			if slotItem.count > 1 then
				widget.setItemSlotItem(wd, {name = slotItem.name, count = slotItem.count - 1, parameters = slotItem.parameters})
			else
				widget.setItemSlotItem(wd, nil)
			end
		end
	end
	
	calculateSellPrice()
end

function calculateSellPrice()
	local total = 0
	
	for row = 1, self.data.shopSellSlots[1] do
		for column = 1, self.data.shopSellSlots[2] do
			local slotItem = widget.itemSlotItem("shopSellSlot"..row..column)
			if slotItem then
				local config = root.itemConfig(slotItem.name)
				local itemPrice = config.config.price
				if itemPrice then
					total = itemPrice * slotItem.count + total
				end
			end
		end
	end
	
	total = calculateShopPrice(total, false)
	widget.setText("shopTotalPrice", tostring(total))
end

function shopSell()
	local money = 0
	
	for row = 1, self.data.shopSellSlots[1] do
		for column = 1, self.data.shopSellSlots[2] do
			local slotItem = widget.itemSlotItem("shopSellSlot"..row..column)
			if slotItem then
				local config = root.itemConfig(slotItem.name)
				local itemPrice = config.config.price
				if itemPrice then
					money = itemPrice * slotItem.count + money
				end
				
				widget.setItemSlotItem("shopSellSlot"..row..column, nil)
			end
		end
	end
	
	money = calculateShopPrice(money, false)
	player.addCurrency("money", money)
	widget.setText("shopTotalPrice", "0")
	
	if money > 0 then
		widget.playSound("/sfx/objects/coinstack_small"..math.random(1,3)..".ogg")
	end
end

function calculateShopPrice(base, isBuying)
	local tradingOutpostMult = 0
	local totalMult = 0
	
	if isBuying then
		if objectData.stationType == "trading" then 
			tradingOutpostMult = objectData.specialsTable.investLevel * stationData.trading.buyPriceReductionPerLevel
		end
		
		totalMult = self.data.shopBuyMult - (status.stat("fuCharisma") - 1) - (tradingOutpostMult * 0.01)
		totalMult = math.max(totalMult, self.data.shopBuyMultMin)
		
		return math.floor(base * totalMult)
	else
		if objectData.stationType == "trading" then 
			tradingOutpostMult = objectData.specialsTable.investLevel * stationData.trading.sellPriceIncreasePerLevel
		end
		
		totalMult = self.data.shopSellMult + (status.stat("fuCharisma") - 1) + (tradingOutpostMult * 0.01)
		totalMult = math.max(math.min(totalMult, self.data.shopSellMultMax), 0)
		
		return math.floor(base * totalMult)
	end
end


------------------------ TRADING GOODS ------------------------
---------------------------------------------------------------
function populateGoodsList()
	goodsListIDs = {}
	
	widget.setVisible("goodsTradeList", true)
	widget.clearListItems("goodsTradeList.itemList")
	
	for _, data in ipairs(stationData.goods) do
		local config = root.itemConfig(data.name)
		local name = config.config.shortdescription
		local stock = objectData.goodsStock[data.name]
		local listItem = "goodsTradeList.itemList."..widget.addListItem("goodsTradeList.itemList")
		
		table.insert(goodsListIDs, listItem)
			
		local buyPrice, buyRate = updatePrice(data.basePrice, data.baseAmount, stock, true)
		local sellPrice, sellRate = updatePrice(data.basePrice, data.baseAmount, stock)
		
		if buyRate >= 1.5 then
			widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:-2")
		elseif buyRate >= 1.2 then
			widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:-1")
		elseif buyRate >= 0.9 then
			widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:0")
		elseif buyRate >= 0.6 then
			widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:1")
		else
			widget.setImage(listItem..".buyRate", "/interface/scripted/spaceStation/tradeRate.png:2")
		end
		
		if sellRate >= 1.5 then
			widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:2")
		elseif sellRate >= 1.2 then
			widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:1")
		elseif sellRate >= 0.9 then
			widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:0")
		elseif sellRate >= 0.6 then
			widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:-1")
		else
			widget.setImage(listItem..".sellRate", "/interface/scripted/spaceStation/tradeRate.png:-2")
		end
		
		widget.setText(listItem..".buyPrice", buyPrice)
		widget.setText(listItem..".sellPrice", sellPrice)
		
		widget.setText(listItem..".stationStockLabel", "Station stock: "..stock)
		widget.setText(listItem..".sellStockLabel", "Your stock:     "..player.currency(data.name))
		
		widget.setText(listItem..".itemName", name)
		widget.setItemSlotItem(listItem..".itemIcon", data.name)
		
		widget.setData(listItem,{
			itemName = config.config.itemName,
			buyPrice = buyPrice,
			sellPrice = sellPrice,
		})
	end
	
	checkGoodsAvailability()
	stationData.selected = nil
end

function checkGoodsAvailability()
	for _, listItem in ipairs(goodsListIDs) do
		local data = widget.getData(listItem)
		
		if player.currency(data.itemName) > 0 then
			widget.setButtonEnabled(listItem..".sellButton", true)
			widget.setFontColor(listItem..".sellStockLabel", "white")
		else
			widget.setButtonEnabled(listItem..".sellButton", false)
			widget.setFontColor(listItem..".sellStockLabel", "red")
		end
		
		if objectData.goodsStock[data.itemName] > 0 then
			if  player.currency("money") >= data.buyPrice then
				widget.setButtonEnabled(listItem..".buyButton", true)
				widget.setFontColor(listItem..".stationStockLabel", "white")
				widget.setFontColor(listItem..".buyPrice", "white")
			else
				widget.setButtonEnabled(listItem..".buyButton", false)
				widget.setFontColor(listItem..".buyPrice", "red")
			end
		else
			widget.setButtonEnabled(listItem..".buyButton", false)
			widget.setFontColor(listItem..".stationStockLabel", "red")
		end
	end
end

function goodsSelected()
	local listItem = widget.getListSelected("goodsTradeList.itemList")
	stationData.selected = listItem
	
	if listItem then
		local itemData = widget.getData("goodsTradeList.itemList."..listItem)
		stationData.selected = itemData
	end
end

function sellGoods()
	if stationData.selected then
		if player.consumeCurrency(stationData.selected.itemName, 1) then
			player.addCurrency("money", stationData.selected.sellPrice)
			
			for _, data in ipairs(stationData.goods) do
				if data.name == stationData.selected.itemName then
					
					objectData.goodsStock[data.name] = objectData.goodsStock[data.name] + 1
					break
				end
			end
			
			populateGoodsList()
		end
	else
		writerInit(textData, "No item selected.\nHow the fuck did you achieve this?\nSeriously, I'm impressed.\n\nReport this I guess?")
	end
end

function buyGoods()
	if stationData.selected then
		if player.consumeCurrency("money", stationData.selected.buyPrice) then
			player.addCurrency(stationData.selected.itemName, 1)
			
			for _, data in ipairs(stationData.goods) do
				if data.name == stationData.selected.itemName then
					objectData.goodsStock[data.name] = objectData.goodsStock[data.name] - 1
					break
				end
			end
			
			populateGoodsList()
		end
	else
		writerInit(textData, "No item selected.\nHow the fuck did you achieve this?\nSeriously, I'm impressed.\n\nReport this I guess?")
	end
end

-- Returns an updated price and rated based on recieved parameters (Basicaly the price formula)
function updatePrice(basePrice, baseAmount, stock, isBuying)
	local rate = 1 - (stock * 100 / baseAmount * 0.01) + 1
	local rateMin = 0.35
	local rateMax = 1.65
	
	if rate < rateMin then
		rate = rateMin
	elseif rate > rateMax then
		rate = rateMax
	end
	
	if isBuying then
		rate = rate * 1.05
	else
		rate = rate * 0.95
	end
	
	local price = basePrice * rate
	
	if price - math.abs(math.floor(price)) < price - math.abs(math.ceil(price)) then
		price = math.floor(price)
	else
		price = math.ceil(price)
	end
	
	return price, rate
end

-- Modifies goods amounts based on time passed since last visit
function simulateGoodTrades()
	local worldTime = world.time()
	if objectData.lastVisit then
		local timePassed = math.floor(worldTime - objectData.lastVisit)
		local trades = math.floor(timePassed / stationData.passiveTradeInterval)
		
		if trades > 0 then
			local goodsState = "normal"
			local tradeAmount = 0
			local striveTo = 0
			local mult = 1
			
			for t = 1, trades do
				for goods, amount in pairs(objectData.goodsStock) do
					goodsState = "normal"
					tradeAmount = 0
					striveTo = 0
					mult = 1
					
					-- Get index, and goods state
					for i, tbl in ipairs(stationData.goods) do
						if goods == tbl.name then
							if type(tbl.abundance) == "table" then
								for _, st in ipairs(tbl.abundance) do
									if objectData.stationType == st then
										goodsState = "abundance"
										break
									end
								end
							elseif tbl.abundance == objectData.stationType then
								goodsState = "abundance"
							end
							
							if goodsState == "normal" then
								if type(tbl.lack) == "table" then
									for _, st in ipairs(tbl.lack) do
										if objectData.stationType == st then
											goodsState = "lack"
											break
										end
									end
								elseif tbl.lack == objectData.stationType then
									goodsState = "lack"
								end
							end
							
							if goodsState == "abundance" then
								mult = math.random(math.floor(stationData.goodsAbundanceRange[1]*100), math.floor(stationData.goodsAbundanceRange[2]*100)) * 0.01
							elseif goodsState == "lack" then
								mult = math.random(math.floor(stationData.goodsLackRange[1]*100), math.floor(stationData.goodsLackRange[2]*100)) * 0.01
							else
								mult = math.random(math.floor(stationData.goodsNormalRange[1]*100), math.floor(stationData.goodsNormalRange[2]*100)) * 0.01
							end
							
							striveTo = stationData.goods[i].baseAmount * mult
							tradeAmount = stationData.goods[i].baseAmount * (math.random(math.floor(stationData.passiveTradePcntOfBaseAmount[1]*100), math.floor(stationData.passiveTradePcntOfBaseAmount[2]*100)) * 0.01)
							
							if amount < striveTo then
								objectData.goodsStock[goods] = closestWhole(objectData.goodsStock[goods] + tradeAmount)
							else
								objectData.goodsStock[goods] = closestWhole(objectData.goodsStock[goods] - tradeAmount)
							end
						end
					end
				end
			end
			objectData.lastVisit = worldTime
		end
	else
		objectData.lastVisit = worldTime
	end
end


---------------------- STATION SPECIALS ----------------------
--------------------------------------------------------------

-- Used for medical and military stations
function populateSpecialList()
	widget.clearListItems("specialsScrollList.itemList")
	
	for _, index in ipairs(objectData.specialsTable) do
		local data = stationData[objectData.stationType][index]
		if data then
			local listItem = "specialsScrollList.itemList."..widget.addListItem("specialsScrollList.itemList")
			widget.setText(listItem..".name",  data[1])
			widget.setImage(listItem..".icon", data[3])
			widget.setText(listItem..".price", "x "..data[2])
			widget.setData(listItem, { index = index, })
		end
	end
	
	stationData.selected = nil
end

function specialSelected()
	local listItem = widget.getListSelected("specialsScrollList.itemList")
	stationData.selected = listItem
	
	if listItem then
		-- stationData.selected = widget.getData(string.format("%s.%s", "specialsScrollList.itemList", listItem))
		stationData.selected = widget.getData("specialsScrollList.itemList."..listItem)
		widget.setButtonEnabled("button1", true)
		
		if objectData.stationType == "medical" then
			writerInit(textData, stationData.medical[stationData.selected.index][6])
		elseif objectData.stationType == "military" then
			writerInit(textData, stationData.military[stationData.selected.index][5])
		else
			writerInit(textData, "ERROR - No or wrong station type")
		end
	else
		widget.setButtonEnabled("button1", false)
		writerInit(textData, "No item selected.\nHow the fuck did you achieve this?\nSeriously, I'm impressed.\n\nReport this I guess?")
	end
end

-- Used for scientific stations
function populateScientificList()
	if true then return false end
	
	widget.clearListItems("scientificSpecialList.itemList")
	scientificListIDs = {}
	
	-- clear skip tags
	for _, index in ipairs(objectData.specialsTable) do
		local data = stationData[objectData.stationType][index]
		if data[5] then data[5] = nil end
	end
	
	for i, index in ipairs(objectData.specialsTable) do
		local data = stationData[objectData.stationType][index]
		if data and not data[5] then -- check if this option was already added
			local listItem = "scientificSpecialList.itemList."..widget.addListItem("scientificSpecialList.itemList")
			table.insert(scientificListIDs, listItem)
			
			widget.setItemSlotItem(listItem..".itemIn1", data[1])
			widget.setItemSlotItem(listItem..".itemOut1", data[3])
			widget.setText(listItem..".amountIn1", data[2])
			widget.setText(listItem..".amountOut1", data[4])
			
			widget.setData(listItem, { indexA = i, })
			local secondData = stationData[objectData.stationType][objectData.specialsTable[i+1]]
			
			if secondData then
				widget.setItemSlotItem(listItem..".itemIn2", secondData[1])
				widget.setItemSlotItem(listItem..".itemOut2", secondData[3])
				widget.setText(listItem..".amountIn2", secondData[2])
				widget.setText(listItem..".amountOut2", secondData[4])
				
				widget.setData(listItem, { indexA = i, indexB = i+1})
				secondData[5] = true
			else
				widget.setVisible(listItem..".amountInBG2", false)
				widget.setVisible(listItem..".amountIn2", false)
				widget.setVisible(listItem..".amountOutBG2", false)
				widget.setVisible(listItem..".amountOut2", false)
				widget.setVisible(listItem..".trade2", false)
			end
		end
	end
	
	checkScientificAvailability()
	stationData.selected = nil
end

function checkScientificAvailability()
	for _, listItem in ipairs(scientificListIDs) do
		local index = widget.getData(listItem).indexA
		local data = stationData.scientific[index]
		
		if player.hasCountOfItem({name = data[1]}, false) < data[2] then
			widget.setButtonEnabled(listItem..".trade1", false)
			widget.setFontColor(listItem..".amountIn1", "red")
		else
			widget.setButtonEnabled(listItem..".trade1", true)
			widget.setFontColor(listItem..".amountIn1", "white")
		end
		
		index = widget.getData(listItem).indexB
		if index then
			data = stationData.scientific[index]
			
			if player.hasCountOfItem({name = data[1]}, false) < data[2] then
				widget.setButtonEnabled(listItem..".trade2", false)
				widget.setFontColor(listItem..".amountIn2", "red")
			else
				widget.setButtonEnabled(listItem..".trade2", true)
				widget.setFontColor(listItem..".amountIn2", "white")
			end
		end
	end
end

function scientificSelected()
	local listItem = widget.getListSelected("scientificSpecialList.itemList")
	stationData.selected = listItem
	
	if listItem then
		stationData.selected = widget.getData(string.format("%s.%s", "scientificSpecialList.itemList", listItem))
	end
end

function tradeA()
	if stationData.selected then
		local inputDescriptor = {
			name = stationData.scientific[stationData.selected.indexA][1],
			count = stationData.scientific[stationData.selected.indexA][2],
		}
		
		if player.hasItem(inputDescriptor, true) then
			player.consumeItem(inputDescriptor, true, true)
			
			local outputDescriptor = {
				name = stationData.scientific[stationData.selected.indexA][3],
				count = stationData.scientific[stationData.selected.indexA][4],
			}
			player.giveItem(outputDescriptor)
		end
	else
		writerInit(textData, "ERROR - Attempted to trade while no item was selected in function 'tradeA'")
	end
end

function tradeB()
	if stationData.selected then
		local inputDescriptor = {
			name = stationData.scientific[stationData.selected.indexB][1],
			count = stationData.scientific[stationData.selected.indexB][2],
		}
		
		if player.hasItem(inputDescriptor, true) then
			player.consumeItem(inputDescriptor, true, true)
			
			local outputDescriptor = {
				name = stationData.scientific[stationData.selected.indexB][3],
				count = stationData.scientific[stationData.selected.indexB][4],
			}
			player.giveItem(outputDescriptor)
		end
	else
		writerInit(textData, "ERROR - Attempted to trade while no item was selected in function 'tradeB'")
	end
end

-- Used for trading stations
function specialsTableInit()
	widget.setVisible("investEmptyBar", true)
	widget.setVisible("investingFillBar", true)
	widget.setVisible("investFillBar", true)
	widget.setVisible("investLevel", true)
	widget.setVisible("investButton", true)
	widget.setVisible("investMax", true)
	widget.setVisible("investAmountBG", true)
	widget.setVisible("investAmount", true)
	widget.setVisible("investRequired", true)
	
	widget.setVisible("benefitsLabel", true)
	widget.setVisible("benefitsBuyPriceLabel", true)
	widget.setVisible("benefitsBuyPriceMult", true)
	widget.setVisible("benefitsSellPriceLabel", true)
	widget.setVisible("benefitsSellPriceMult", true)
	
	widget.setText("investLevel", "Lvl "..tostring(objectData.specialsTable.investLevel))
	widget.setText("benefitsBuyPriceMult", "-"..tostring(objectData.specialsTable.investLevel * stationData.trading.buyPriceReductionPerLevel).."%")
	widget.setText("benefitsSellPriceMult", "+"..tostring(objectData.specialsTable.investLevel * stationData.trading.sellPriceIncreasePerLevel).."%")
		
	widget.setVisible("playerPixels", true)
	widget.setPosition("playerPixels", self.data.pixelDisplayInvestPos)
	
	if objectData.specialsTable.investLevel < stationData.trading.investMaxLevel then
		widget.setText("investRequired", "Required: "..tostring(objectData.specialsTable.investRequired - objectData.specialsTable.invested))
		writerInit(textData, textData[objectData.stationRace].tradingSpecial)
	else
		writerInit(textData, textData[objectData.stationRace].tradingSpecialMax)
		widget.setText("investRequired", "Fully upgraded!")
		widget.setButtonEnabled("investButton", false)
		widget.setButtonEnabled("investMax", false)
		widget.setText("investAmount", "")
	end
end

function invest()
	objectData.specialsTable.invested = objectData.specialsTable.invested + objectData.specialsTable.investing
	player.consumeCurrency("money", objectData.specialsTable.investing)
	
	-- Level up if you reach the milestone
	if objectData.specialsTable.invested >= objectData.specialsTable.investRequired then
		objectData.specialsTable.invested = 0
		objectData.specialsTable.investLevel = objectData.specialsTable.investLevel + 1
		widget.setText("investLevel", "Lvl "..tostring(objectData.specialsTable.investLevel))
		
		objectData.specialsTable.investRequired = 100 + (objectData.specialsTable.investLevel * 123)
	end
	
	-- Disable some elements and increase charisma stat when reaching max level
	if objectData.specialsTable.investLevel >= stationData.trading.investMaxLevel then
		writerInit(textData, textData[objectData.stationRace]["specialsTableMax"])
		widget.setText("investRequired", "Fully upgraded!")
		widget.setButtonEnabled("investButton", false)
		widget.setButtonEnabled("investMax", false)
		widget.setText("investAmount", "")
		
		-- Increase max level stations counter
	else
		objectData.specialsTable.investing = 0
		widget.setText("investAmount", "")
		widget.setText("investRequired", "Required: "..tostring(objectData.specialsTable.investRequired - objectData.specialsTable.invested))
	end
	
	widget.setText("benefitsBuyPriceMult", "-"..tostring(objectData.specialsTable.investLevel * stationData.trading.buyPriceReductionPerLevel).."%")
	widget.setText("benefitsSellPriceMult", "+"..tostring(objectData.specialsTable.investLevel * stationData.trading.sellPriceIncreasePerLevel).."%")
	
	updateBar(false)
	updateBar(true)
end

function investMax()
	objectData.specialsTable.investing = math.min(math.min(objectData.specialsTable.investRequired - objectData.specialsTable.invested, 99999), player.currency("money"))
	widget.setText("investAmount", objectData.specialsTable.investing)
end

function investAmount(wd)
	local value = tonumber(widget.getText(wd))
	local max = objectData.specialsTable.investRequired - objectData.specialsTable.invested
	
	if objectData.specialsTable.investLevel >= stationData.trading.investMaxLevel then
		widget.setText(wd, "")
	else
		if value then
			value = math.min(math.min(math.floor(value), max), player.currency("money"))
			if value == 0 then
				widget.setText(wd, "")
				objectData.specialsTable.investing = 0
				updateBar(false)
			else
				widget.setText(wd, value)
				objectData.specialsTable.investing = value
				updateBar(false)
			end
		else
			widget.setText(wd, "")
			objectData.specialsTable.investing = 0
			updateBar(false)
		end
	end
end

function updateBar(real)
	local bar = "investFillBar"
	if not real then bar = "investingFillBar" end
	
	local size = {0, 6} -- Full size = 120, 6
	if objectData.specialsTable.investLevel >= stationData.trading.investMaxLevel then
		size[1] = 120
	else
		if real then
			size[1] = (objectData.specialsTable.invested / objectData.specialsTable.investRequired) * 120
		else
			size[1] = ((objectData.specialsTable.investing + objectData.specialsTable.invested) / objectData.specialsTable.investRequired) * 120
		end
	end
	
	widget.setSize(bar, size)
end


---------------------------------------------------------------
---------------------------------------------------------------

-- Prints to log all items in all shop lists, letting you easily find the broken/non-existant ones
-- Has to be manually added somewhere to the code as its not called anywhere
function checkShopIntegrity()
	sb.logError("")
	for type, t in pairs(stationData.shop.potentialStock) do
		for _, item in ipairs(t) do
			local config = root.itemConfig(item)
			
			sb.logError("-----")
			sb.logError("type - %s", type)
			sb.logError("item - %s", item)
			sb.logError("config - "..tostring(config))
		end
	end
end

-- Returns a specified amount of randomized indexes from an ipairs table.
function getRandomTableIndexes(tbl, amount)
	local passed = false
	local indexes = {}
	local pulled = 0
	local index = 0
	
	-- Return all indexes if the amount exceeds the tables length
	if #tbl <= amount then
		for i = 1, #tbl do
			table.insert(indexes, i)
		end
		return indexes
	end
	
	while pulled <= amount do
		passed = false
		while not passed do
			passed = true
			index = math.random(1, #tbl)
			for _, indexed in ipairs(indexes) do
				if index == indexed then
					passed = false
					break
				end
			end
			
			if passed then
				pulled = pulled + 1
				table.insert(indexes, index)
			end
		end
	end
	
	return indexes
end

-- Save data into the station object
function uninit()
	writerStopSounds(textData)
	world.sendEntityMessage(objectID, 'setInteractable', true)
	
	if objectData and type(objectData) == "table" then
		
		if objectData.stationType == "trading" then
			objectData.specialsTable.investing = 0
		end
		
		-- Give back all the items stored in the shops sell menu
		for row = 1, self.data.shopSellSlots[1] do
			for column = 1, self.data.shopSellSlots[2] do
				local slotItem = widget.itemSlotItem("shopSellSlot"..row..column)
				if slotItem then
					world.spawnItem(slotItem, world.entityPosition(player.id()))
				end
			end
		end
		
		world.sendEntityMessage(objectID, 'setStorage', objectData)
	else
		sb.logError("objectData is missing! Data was not saved in an object!", "")
	end
end

-- Recieves a single number, and returns a table holding seconds, minutes, and hours as if the value recieved was seconds
function toTime(time)
	local table = {
		seconds = math.floor(time % 60),
		minutes = math.floor((time / 60) % 60),
		hours = math.floor((time / 60 / 60)),
	}
	return table
end

-- Returns the closest whole number to the given fraction
function closestWhole(num)
	local low = math.floor(num)
	local high = math.ceil(num)
	
	if math.abs(num - low) < math.abs(num - high) then
		if num < 0 then
			return low * -1
		else
			return low
		end
	else
		if num < 0 then
			return high * -1
		else
			return high
		end
	end
end
