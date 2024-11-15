require "/scripts/util.lua"

local detectorItem,inEssentialSlot,inBothHands
local stringData={}

function init()
	widget.setVisible("lb_Info", true)
	self.errorSound = config.getParameter("errorSound")
	self.successSound = config.getParameter("successSound")
	refreshDetector()
	stringData=config.getParameter("stringData") or {}
	if inEssentialSlot then
		itemError("EquippedEssential")
	elseif inBothHands  then
		itemError("MultipleScanner")
	end
	self.itemInSlot = nil
	self.delay = 2
	self.timer = 0
end

function refreshDetector()
	detectorItem,inEssentialSlot,inBothHands = detectorInHand()
	if detectorItem then
		self.oreList = root.itemConfig(detectorItem).config.oreList
		if detectorItem.parameters.currentTargetOre then
			local target
			for item,params in pairs(self.oreList) do
				if params[1]==detectorItem.parameters.currentTargetOre then
					target=root.itemConfig(item).config.shortdescription
					break
				end
			end
			--sb.logInfo("EEE: %s %s",detectorItem.parameters.currentTargetOre,target)
			--sb.logInfo("E: %s",self.oreList)
			widget.setText("lb_currentOre",target or "<^red;ERROR^reset;>")
			widget.setText("currentOreLabel","^yellow;Current Ore:")
		end
	else
		self.oreList={}
	end
end

function update(dt)
	if self.itemInSlot then
		self.timer = self.timer + dt
		if self.timer >= self.delay then
			refreshDetector()
			--is one of the ores in the list
			if detectorItem and self.oreList[self.itemInSlot.name] then
				if detectorItem and (not inEssentialSlot) and (not inBothHands) then
					local upgradeLevel = detectorItem.parameters.level or root.itemConfig(detectorItem).config.level
					if upgradeLevel >= self.oreList[self.itemInSlot.name][2] then
						local newDetectorItem = copy(detectorItem)
						newDetectorItem.parameters.currentTargetOre = self.oreList[self.itemInSlot.name][1]

						--use exact match in case player has several detectors
						local pass=player.consumeItem(detectorItem, false, true)
						if pass then
							player.giveItem(newDetectorItem)
						else
							--couldnt consume, abort.
							itemError("MissingScanner")
							return
						end

						--give back the ore to the player before closing the panel
						player.giveItem(self.itemInSlot)
						self.itemInSlot = nil
						widget.setItemSlotItem("oreSlot",nil)
						self.timer = 0
						pane.playSound(self.successSound)
						pane.dismiss()

					else
						--need to level up
						itemError("UpgradeRequired")
					end
				elseif inEssentialSlot then
					--exploit fix, for a case which allowed spawning infinite detectors.
					itemError("EquippedEssential")
					return
				elseif inBothHands then
					--warn that more than one were detected in hand.
					itemError("MultipleScanner")
					return
				end
			--ore not in list
			elseif detectorItem then
				--incorrect item
				itemError("WrongItem")
			else
				--couldnt pick scanner
				itemError("MissingScanner")
			end
		end
	end
end

function itemSlotCallback(widgetName)
	if player.swapSlotItem() then
		widget.setText("lb_Info",stringData["Scanning"] or "^yellow;<STR:Scanning>")
		widget.setItemSlotItem(widgetName,player.swapSlotItem())
		self.itemInSlot = widget.itemSlotItem(widgetName)
		player.setSwapSlotItem(nil)
	end
end

function detectorInHand()
	local itemPrimary = player.primaryHandItem()
	local itemAlt = player.altHandItem()
	local inEssentialSlot=false -- luacheck: ignore 431/inEssentialSlot
	local inPrimary=false
	local inAlt=false

	for _,v in pairs({ "beamaxe", "wiretool", "painttool", "inspectiontool"}) do
		local test=player.essentialItem(v)
		if test and test.name=="tunableoredetector1" then
			inEssentialSlot=true
			break
		end
	end
	if itemPrimary then
		if itemPrimary.name == "tunableoredetector1" then inPrimary=true end
	end
	if itemAlt then
		if itemAlt.name == "tunableoredetector1" then inAlt=true end
	end

	local inBoth=inAlt and inPrimary
	if not inBoth then
		return (inPrimary and itemPrimary) or (inAlt and itemAlt),inEssentialSlot,inBoth
	else
		return nil,inEssentialSlot,inBoth
	end
end

function itemError(errorType)
	widget.setText("lb_Info",stringData[errorType] or "^red;<STR:"..errorType..">")
	pane.playSound(self.errorSound)
	if self.itemInSlot then
		player.giveItem(self.itemInSlot)
		self.itemInSlot = nil
	end
	widget.setItemSlotItem("oreSlot",nil)
	self.timer = 0
end

function closePanel()
	local oreSlotItem =  widget.itemSlotItem("oreSlot")
	if oreSlotItem then
		player.giveItem(oreSlotItem)
	end
	pane.dismiss()
end

function uninit()
	local oreSlotItem =  widget.itemSlotItem("oreSlot")
	if oreSlotItem then
		player.giveItem(oreSlotItem)
	end
end
