require "/scripts/util.lua"


function init()
		
	self.errorSound = config.getParameter("errorSound")
	self.successSound = config.getParameter("successSound")
	local detectorItem = detectorInHand()
	self.oreList = root.itemConfig(detectorItem).config.oreList
	self.itemInSlot = nil
	self.delay = 2
	self.timer = 0
end


function update(dt)	
	
	if self.itemInSlot then
		self.timer = self.timer + dt
		if self.timer >= self.delay then
						
			--check if item is one of the ores in the list
			if self.oreList[self.itemInSlot.name] then
				widget.setVisible("lb_Scanning", false)
				local detectorItem = detectorInHand()
				local upgradeLevel = detectorItem.parameters.level or root.itemConfig(detectorItem).config.level
				
				if upgradeLevel >= self.oreList[self.itemInSlot.name][2] then
					local newDetectorItem = copy(detectorItem)
					newDetectorItem.parameters.currentTargetOre = self.oreList[self.itemInSlot.name][1]
						
					--use exact match in case player has several detectors
					player.consumeItem(detectorItem, false, true)
					player.giveItem(newDetectorItem)
			
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
				
			else
				--incorrect item
				itemError("WrongItem")
			end
			
		end			
		
	end
	
end
	
	
function itemSlotCallback(widgetName)
	
	if player.swapSlotItem() then
		clearLabels()
		widget.setVisible("lb_Scanning", true)
		widget.setItemSlotItem(widgetName,player.swapSlotItem())
		self.itemInSlot = widget.itemSlotItem(widgetName)
		player.setSwapSlotItem(nil)
	end
	
end


function detectorInHand()

	local itemPrimary = player.primaryHandItem()
	local itemAlt = player.altHandItem()
	if itemPrimary then
		if itemPrimary.name == "tunableoredetector1" then return itemPrimary end
	end
			
	if itemAlt then 
		if itemAlt.name == "tunableoredetector1" then return itemAlt end
	end
	
	return nil
end

function itemError(errorType)

	clearLabels()
	pane.playSound(self.errorSound)
	widget.setVisible("lb_"..errorType, true)
	player.giveItem(self.itemInSlot)
	self.itemInSlot = nil
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

function clearLabels()
	widget.setVisible("lb_UpgradeRequired", false)
	widget.setVisible("lb_WrongItem", false)
	widget.setVisible("lb_Scanning", false)

end


