require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/furesearchGenerators.lua"

local cosmeticList={legwear=true,chestwear=true,headwear=true,backwear=true}
local armorList={legarmour=true,chestarmour=true,headarmour=true,enviroProtectionPack=true}
local cosmeticSlotList={"headCosmetic", "chestCosmetic", "legsCosmetic", "backCosmetic"}
local armorSlotList={"head", "chest", "legs", "back"}
local textboxPulseInterval=1.0
local upgradeButtonLockout=1.5

function init()
	widget.setButtonEnabled("btnUpgradeMax", false)
	self.itemList = "itemScrollArea.itemList"
	self.tableType = config.getParameter("upgradeTableType")
	self.isCrucible = self.tableType ~= 1
	self.isUpgradeKit = self.tableType == 3
	if self.isCrucible then
		self.upgradeLevel = 10
		self.maxEssenceValue=root.evalFunction("weaponEssenceValue", self.upgradeLevel)
	else
		self.upgradeLevel = 6
	end
	self.upgradeLevelTool = 20
	self.upgradeableWeaponItems = {}
	self.selectedItem = nil
	self.targetText = widget.getText("upgradeTargetText")

	populateItemList()

	widget.setText("warningLabel","")
end

function update(dt)
	self.buttonTimer=math.max(self.playerTypingTimer or upgradeButtonLockout,(self.buttonTimer or upgradeButtonLockout)-dt)
	self.playerTypingTimer=math.max(0,(self.playerTypingTimer or upgradeButtonLockout)-dt)
	self.textboxPulseTimer=math.max(0,(self.textboxPulseTimer or textboxPulseInterval)-dt)
	populateItemList()
	itemSelected()
	pulseTextbox()
end

function fetchTags(iConf)
	local tags={}
	for k,v in pairs(iConf.config or {}) do
		if string.lower(k)=="itemtags" then
			tags=util.mergeTable(tags,copy(v))
		end
	end
	for k,v in pairs(iConf.parameters or {}) do
		if string.lower(k)=="itemtags" then
			tags=util.mergeTable(tags,copy(v))
		end
	end
	return tags
end

function matchAny(str,tbl)
	for _,v in pairs(tbl) do
		if v==str then
			return true
		end
	end
	return false
end

function itemHasTag(item,tag)
	local tagData=fetchTags(item)
	for _,v in pairs(tagData) do
		if string.lower(v)==string.lower(tag) then
			return true
		end
	end
	return false
end

function highestRarity(rarity2,rarity1)
	local t={common=1,uncommon=2,rare=3,legendary=4,essential=5}
	rarity1=string.lower(rarity1 or "")
	rarity2=string.lower(rarity2 or "")
	if (t[rarity1] or 0)> (t[rarity2] or 0) then return rarity1 else return rarity2 end
end

function upgradeCost(itemConfig,type,targetLvl)
	local costValue=0
	local itemLvl = math.floor((itemConfig.parameters.level or itemConfig.config.level) or 1)
	if not targetLvl then
		targetLvl = itemLvl
	end
	if not self.isCrucible then -- modules
		if type == "weapon" then
			for i=itemLvl,targetLvl-1 do
				costValue=costValue+i
			end
		elseif type == "tool" then
			for i=itemLvl,targetLvl-1 do
				costValue=costValue+(root.evalFunction("minerModuleValue", i)*3)*(itemConfig.config.upmod or 1)
			end
		end
	elseif self.isUpgradeKit then -- upgrade kits
		costValue=targetLvl-itemLvl
	else -- essence
		for i=itemLvl,targetLvl-1 do
			costValue=costValue+essenceMath(i)
		end
	end
	return math.floor(costValue)
end

function maxLvl(item,type)
	local itemConfig
	if item.config then
		itemConfig = item
	else
		itemConfig = root.itemConfig(item)
	end
	if itemConfig.config.upmax then
		if type == "weapon" and not self.isCrucible and self.upgradeLevel < itemConfig.config.upmax then
			return self.upgradeLevel
		end
		return itemConfig.config.upmax
	end
	if type == "tool" then
		return self.upgradeLevelTool
	end
	return self.upgradeLevel
end

function essenceMath(iLvl)
	local prevValue = root.evalFunction("weaponEssenceValue", iLvl)
	local newValue = (self.maxEssenceValue * iLvl / 3) + 200
	return math.max(math.floor(newValue-prevValue),0)
end

function getCurrency(type)
	if not self.isCrucible then
		if type == "weapon" then
			return player.hasCountOfItem("upgrademodule")
		elseif type == "tool" then
			return player.hasCountOfItem("manipulatormodule")
		end
	elseif self.isUpgradeKit then
		return player.hasCountOfItem("cuddlehorse")
	else
		return player.currency("essence")
	end
	return 0
end

function consumeCurrency(cost,type)
	if cost == 0 then return end
	if not self.isCrucible then
		if type == "weapon" then
			return player.consumeItem({name = "upgrademodule", count = cost})
		elseif type == "tool" then
			return player.consumeItem({name = "manipulatormodule", count = cost})
		end
	elseif self.isUpgradeKit then
		return player.consumeItem({name = "cuddlehorse", count = cost})
	else
		return player.consumeCurrency("essence", cost)
	end
	return false
end

function populateItemList(forceRepop)
	local upgradeableWeaponItems = player.itemsWithTag("upgradeableWeapon")
	local upgradeableToolItems = player.itemsWithTag("upgradeableTool")
	local upgradableItems={}

	for i = 1, #upgradeableWeaponItems do
		local monkeys=deepSizeOf(upgradeableWeaponItems[i])
		if monkeys <=250 then
			upgradeableWeaponItems[i].count = 1
			local itemLevel
			if upgradeableWeaponItems[i].parameters.level then
				itemLevel = upgradeableWeaponItems[i].parameters.level
			else
				local itemConfig = root.itemConfig(upgradeableWeaponItems[i])
				if itemConfig.config.level then
					itemLevel = itemConfig.config.level
				else
					itemLevel = 1
				end
			end
			table.insert(upgradableItems,{itemData=upgradeableWeaponItems[i],itemType="weapon",itemLevel=itemLevel})
		end
	end

	for i = 1, #upgradeableToolItems do
		local monkeys=deepSizeOf(upgradeableToolItems[i])
		if monkeys <=250 then
			upgradeableToolItems[i].count = 1
			local itemLevel
			if upgradeableToolItems[i].parameters.level then
				itemLevel = upgradeableToolItems[i].parameters.level
			else
				local itemConfig = root.itemConfig(upgradeableToolItems[i])
				if itemConfig.config.level then
					itemLevel = itemConfig.config.level
				else
					itemLevel = 1
				end
			end
			table.insert(upgradableItems,{itemData=upgradeableToolItems[i],itemType="tool", itemLevel=itemLevel})
		end
	end

	widget.setVisible("emptyLabel", #upgradableItems == 0)

	if forceRepop or not compare(upgradableItems, self.upgradableItems) then
		widget.clearListItems(self.itemList)
		widget.setButtonEnabled("btnUpgrade", false)
		self.upgradableItems = upgradableItems
		--widget.clearListItems(self.itemList)
		--widget.setButtonEnabled("btnUpgrade", false)

		for i, item in pairs(self.upgradableItems) do
			local config = root.itemConfig(item.itemData)
			local entryLevelMax=maxLvl(config,item.itemType)
			if (self.isCrucible and not self.isUpgradeKit) or (config.parameters.level or config.config.level or 1) < entryLevelMax then
				local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
				local name = config.parameters.shortdescription or config.config.shortdescription

				widget.setText(string.format("%s.itemName", listItem), name)
				widget.setItemSlotItem(string.format("%s.itemIcon", listItem), item.itemData)

				local price = upgradeCost(config,item.itemType,math.min(item.itemLevel+1, entryLevelMax))
				widget.setData(listItem, { index = i,itemType = item.itemType,itemLevel = item.itemLevel })
				if self.isUpgradeKit or not self.isCrucible then
					widget.setVisible(string.format("%s.unavailableoverlay", listItem), getCurrency(item.itemType)<price)
				else
					widget.setVisible(string.format("%s.unavailableoverlay", listItem), false)
				end
			end
		end

		self.selectedItem = nil
		showItem(nil)
	end
end

function showItem(item,price,itemType)
	local enableButton=false
	local isWorn=checkWorn(item)

	if item and itemType then
		local upgradeCurrency = getCurrency(itemType)
		local directive = (upgradeCurrency >= price) and "^green;" or "^red;"
		enableButton = (upgradeCurrency >= price)
		widget.setText("essenceCost", string.format("%s%s / %s", directive, upgradeCurrency, price))
	elseif self.isCrucible then
		widget.setText("essenceCost", string.format("%s / --", getCurrency(nil)))
	else
		widget.setText("essenceCost", string.format("0 / --"))
	end
	local downgrade=""
	if item and item.parameters.level and (item.parameters.level > maxLvl(item, itemType)) then
		downgrade="Warning: Item will be downgraded"
	end
	widget.setText("warningLabel",isWorn and "Error: "..isWorn or downgrade)

	if not self.isCrucible then
		widget.setVisible("upgradeIcon",itemType=="weapon")
		widget.setVisible("manipIcon",itemType=="tool")
	end
	widget.setButtonEnabled("btnUpgrade", ((self.buttonTimer and self.buttonTimer or upgradeButtonLockout) <= 0) and enableButton and not isWorn)
end

function getSelectedItem()
	if not self.selectedItem then return end
	return self.upgradableItems[widget.getData(string.format("%s.%s", self.itemList, self.selectedItem)).index].itemData
end

function itemSelected()
	local listItem = widget.getListSelected(self.itemList)
	local changed = false
	local localItem = {}
	if listItem ~= self.selectedItem then
		changed = true
	end
	self.selectedItem = listItem

	if listItem then
		local listItem = widget.getData(string.format("%s.%s", self.itemList, listItem))
		localItem = self.upgradableItems[listItem.index]
		local cost = upgradeCost(root.itemConfig(localItem.itemData), localItem.itemType, self.upgradeTargetLevel)
		showItem(localItem.itemData,cost,localItem.itemType)
	end
	if self.playerTypingTimer and self.playerTypingTimer <= 0 then
		fixTargetText(changed, localItem.itemData, localItem.itemType)
	end
end

function fixTargetText(changed, item, itemType)
	local originalText = widget.getText("upgradeTargetText")
	local text = originalText
	local num=((not changed) and tonumber(text)) or 0
	if not item then
		text=""
		self.upgradeTargetLevel=nil
	else
		item=root.itemConfig(item)
		local itemLevel=math.floor(item.parameters.level or item.config.level or 1)
		if self.isUpgradeKit or not self.isCrucible then
			num=math.max(itemLevel+1,num)
		else
			num=math.max(itemLevel+(changed and 1 or 0),num)
		end
		num=math.min(maxLvl(item, itemType),num)
		self.upgradeTargetLevel=num
		text=num..""
		if num==itemLevel then
			widget.setText("btnUpgrade","Infuse")
		else
			widget.setText("btnUpgrade","Upgrade")
		end
	end
	if originalText~=text then
		widget.setText("upgradeTargetText",text)
		self.playerTypingTimer=upgradeButtonLockout/4
		self.buttonTimer=upgradeButtonLockout/4
		widget.setButtonEnabled("btnUpgrade", false)
		itemSelected()
	end
end

function pulseTextbox()
	if self.textboxPulseTimer>0 then return end
	if not self.textboxColor then
		self.textboxColor=true
	else
		self.textboxColor=not self.textboxColor
	end
	widget.setFontColor("upgradeTargetText",self.textboxColor and {192,192,192} or {128,128,128})

	self.textboxPulseTimer=textboxPulseInterval
end

function btnUpgradeMax()
--deprecated. do not use.
end

function doUpgrade()
	if self.selectedItem then
		local isWorn=checkWorn(getSelectedItem())
		if isWorn then
			widget.setText("warningLabel",isWorn and "Error: "..isWorn or "")
			widget.setButtonEnabled("btnUpgrade", false)
			return
		end

		local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))
		local upgradeItemInfo = self.upgradableItems[selectedData.index]
		if upgradeItemInfo.itemType=="weapon" then
			local pass,result=pcall(upgradeWeapon,upgradeItemInfo.itemData,self.upgradeTargetLevel)
			if not pass then
				player.giveItem(upgradeItemInfo.itemData)
				sb.logInfo("Upgrade (weapon/armor) failed: %s",result)
			elseif not result.completed then
				if result.consumedItem then
					player.giveItem(upgradeItemInfo.itemData)
				end
			end
		elseif upgradeItemInfo.itemType=="tool" then
			local pass,result=pcall(upgradeTool,upgradeItemInfo.itemData,self.upgradeTargetLevel)
			if not pass then
				player.giveItem(upgradeItemInfo.itemData)
				sb.logInfo("Upgrade (tool) failed: %s",result)
			elseif not result.completed then
				if result.consumedItem then
					player.giveItem(upgradeItemInfo.itemData)
				end
			end
		end
		if self.isUpgradeKit and getCurrency(nil) <= 0 then
			pane.dismiss()
		else
			populateItemList(true)
		end
	end
end

function checkWorn(item)
	if not item then return "no item selected" end
	local itemCat=root.itemConfig(item)
	if itemCat and itemCat.parameters and itemCat.parameters.category then
		itemCat=itemCat.parameters.category
	elseif itemCat and itemCat.config and itemCat.config.category then
		itemCat=itemCat.config.category
	else
		return "category missing"
	end
	local swapSlotItem=player.swapSlotItem()
	local isCosmeticArmor=cosmeticList[itemCat]
	local isArmor=armorList[itemCat]
	if isCosmeticArmor or isArmor then
		for _,slot in pairs(cosmeticSlotList) do
			local compTo=player.equippedItem(slot)
			if compare(compTo,item) then return "equipped in cosmetic slot" end
		end
		for _,slot in pairs(armorSlotList) do
			local compTo=player.equippedItem(slot)
			if compare(compTo,item) then return "equipped in armor slot" end
		end
	end
	if compare(swapSlotItem,item) then return "held by mouse" end
	return false
end

function upgradeTargetText()
	local text = widget.getText("upgradeTargetText")
	if self.targetText ~= text then
		self.playerTypingTimer = upgradeButtonLockout
		self.buttonTimer = upgradeButtonLockout
		self.targetText = text
	end
end

function upgradeWeapon(upgradeItem,target)
	--local upgradeItem=getSelectedItem()
	local upgradeStates={}
	if upgradeItem then
		if checkWorn(upgradeItem) then
			return
		end
		local consumedItem = player.consumeItem(upgradeItem, false, true)
		if consumedItem then
			upgradeStates.consumedItem=true
			local upCost=upgradeCost(root.itemConfig(consumedItem),"weapon",target)
			local consumedCurrency = consumeCurrency(upCost, "weapon")
			local upgradedItem = copy(consumedItem)
			if consumedCurrency or upCost==0 then
				upgradeStates.consumeCurrency=upCost
				local itemConfig = root.itemConfig(upgradedItem)
				local mergeBuffer={}
				local oldRarity=itemConfig.parameters.rarity or itemConfig.config.rarity
				mergeBuffer.rarity=oldRarity

				sb.logInfo("Pre-Upgrade Stats: \n"..sb.printJson(upgradedItem,1)) -- list all current bonuses being applied to the weapon for debug

				--set level
				local maxLvl=maxLvl(itemConfig, "weapon")
				local defaultLvl=(itemConfig.config.level or 1)
				--mergeBuffer.level = math.min((itemConfig.parameters.level or itemConfig.config.level or 1)+1,maxLvl)
				mergeBuffer.level = math.min((itemConfig.parameters.level or itemConfig.config.level or 1),maxLvl)
				if target then
					mergeBuffer.level=math.min(math.max(mergeBuffer.level,target),maxLvl)
				end

				--load item upgrade parameters
				if (itemConfig.config.upgradeParametersTricorder) and (mergeBuffer.level > 1) then
					oldRarity=mergeBuffer.rarity
					mergeBuffer=util.mergeTable(mergeBuffer,copy(itemConfig.config.upgradeParametersTricorder))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
				end
				if (itemConfig.config.upgradeParameters) and (mergeBuffer.level > math.max(defaultLvl, 4)) then
					oldRarity=mergeBuffer.rarity
					mergeBuffer=util.mergeTable(mergeBuffer,copy(itemConfig.config.upgradeParameters))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
				end
				if (itemConfig.config.upgradeParameters2) and (mergeBuffer.level > math.max(defaultLvl+1, 5)) then
					oldRarity=mergeBuffer.rarity
					mergeBuffer=util.mergeTable(mergeBuffer,copy(itemConfig.config.upgradeParameters2))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
				end
				if (itemConfig.config.upgradeParameters3) and (mergeBuffer.level > math.max(defaultLvl+2, 6)) then
					oldRarity=mergeBuffer.rarity
					mergeBuffer=util.mergeTable(mergeBuffer,copy(itemConfig.config.upgradeParameters3))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
				end

				local categoryLower=string.lower(mergeBuffer.category or itemConfig.parameters.category or itemConfig.config.category or "")

				-- set Rarity
				if mergeBuffer.level >= 7 then
					mergeBuffer.rarity = highestRarity("essential",mergeBuffer.rarity)
				elseif mergeBuffer.level >= 6 and self.isCrucible then
					mergeBuffer.rarity = highestRarity("legendary",mergeBuffer.rarity)
				elseif mergeBuffer.level >= 5 then
					mergeBuffer.rarity = highestRarity("rare",mergeBuffer.rarity)
				elseif mergeBuffer.level >= 4 then
					mergeBuffer.rarity = highestRarity("uncommon",mergeBuffer.rarity)
				end

				if self.isCrucible then
					applyBonusesEssence(mergeBuffer, itemConfig, categoryLower)
				else
					applyBonusesModule(mergeBuffer, itemConfig, categoryLower)
				end

				upgradedItem.parameters=util.mergeTable(copy(upgradedItem.parameters),copy(mergeBuffer))
				upgradeStates.completed=true
			end

			-- check if player gets Research randomly
			if upgradeStates.completed then
				player.giveItem(upgradedItem)
				checkResearchBonus()
				sb.logInfo("Upgraded Stats: \n"..sb.printJson(upgradedItem,1)) -- list all current bonuses being applied to the weapon for debug
			end
			--player.giveItem(upgradedItem)
			return upgradeStates
		end
	end
end

function upgradeTool(upgradeItem, target)
	local upgradeStates={}
	if upgradeItem then
		if checkWorn(upgradeItem) then
			return
		end
		local consumedItem = player.consumeItem(upgradeItem, false, true)
		if consumedItem then
			upgradeStates.consumedItem=true
			local upCost=upgradeCost(root.itemConfig(consumedItem),"tool",target)
			local consumedCurrency = consumeCurrency(upCost, "tool")
			local upgradedItem = copy(consumedItem)
			if consumedCurrency or upCost==0 then
				upgradeStates.consumeCurrency=upCost
				local itemConfig = root.itemConfig(upgradedItem)
				local mergeBuffer={}
				local oldRarity=itemConfig.parameters.rarity or itemConfig.config.rarity
				mergeBuffer.rarity=oldRarity

				sb.logInfo("Pre-Upgrade Stats: \n"..sb.printJson(upgradedItem,1)) -- list all current bonuses being applied to the weapon for debug
				--set level
				local maxLvl=maxLvl(itemConfig, "tool")
				--mergeBuffer.level = math.min((itemConfig.parameters.level or itemConfig.config.level or 1)+1,maxLvl)
				mergeBuffer.level = math.min((itemConfig.parameters.level or itemConfig.config.level or 1),maxLvl)
				if target then
					mergeBuffer.level=math.min(math.max(mergeBuffer.level,target),maxLvl)
				end

				if (itemConfig.config.upgradeParameters) and (mergeBuffer.level > 1) then
					mergeBuffer=util.mergeTable(mergeBuffer,copy(itemConfig.config.upgradeParameters))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
					oldRarity=mergeBuffer.rarity
				end

				for i=2,maxLvl-1 do
					if itemConfig.config["upgradeParameters"..i] and (mergeBuffer.level > i) then
						mergeBuffer=util.mergeTable(mergeBuffer,copy(itemConfig.config["upgradeParameters"..i]))
						mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
						oldRarity=mergeBuffer.rarity
					end
				end

				-- set rarity
				if mergeBuffer.level >= 8 then
					mergeBuffer.rarity = highestRarity("essential",mergeBuffer.rarity)
				elseif mergeBuffer.level >= 7 then
					mergeBuffer.rarity = highestRarity("legendary",mergeBuffer.rarity)
				elseif mergeBuffer.level >= 5 then
					mergeBuffer.rarity = highestRarity("rare",mergeBuffer.rarity)
				elseif mergeBuffer.level >= 3 then
					mergeBuffer.rarity = highestRarity("uncommon",mergeBuffer.rarity)
				end

				local categoryLower=string.lower(mergeBuffer.category or itemConfig.parameters.category or itemConfig.config.category or "")

				-- specific tool bonuses
				if itemHasTag(itemConfig,"mininglaser") and mergeBuffer.level > 8 and itemConfig.config.upgradeParameters8 then
					mergeBuffer.primaryAbility.beamLength = 30 + ( mergeBuffer.level + 1 )
					mergeBuffer.primaryAbility.energyUsage = 6 + ( mergeBuffer.level /10 )
					mergeBuffer.primaryAbility.baseDps = itemConfig.config.primaryAbility.baseDps + ( mergeBuffer.level /10 )
				elseif categoryLower == "bugnet" and mergeBuffer.level > 8 and itemConfig.config.upgradeParameters8 then
					mergeBuffer.primaryAbility.energyUsage = 1 + ( mergeBuffer.level /20 )
					mergeBuffer.primaryAbility.baseDps = itemConfig.config.primaryAbility.baseDps + ( mergeBuffer.level /10 )
				elseif categoryLower == "mechrepairtool" and mergeBuffer.level > 8 and itemConfig.config.upgradeParameters8 then
					mergeBuffer.primaryAbility.projectileParameters.restoreBase = (mergeBuffer.level) + 3
					mergeBuffer.primaryAbility.projectileParameters.speed = (mergeBuffer.level)+1
					mergeBuffer.primaryAbility.energyUsage = 10 + ( mergeBuffer.level /10 )
				elseif categoryLower == "detector" and mergeBuffer.level >= 8 and itemConfig.config.upgradeParameters8 then
					-- ore detectors and cave detectors
					mergeBuffer.pingRange = mergeBuffer.pingRange + 1
					mergeBuffer.pingDuration = mergeBuffer.pingDuration + 0.15
					mergeBuffer.pingCooldown = mergeBuffer.pingCooldown - 0.05
				end

				upgradedItem.parameters=util.mergeTable(copy(upgradedItem.parameters),copy(mergeBuffer))
				upgradeStates.completed=true
			end
			-- check if player gets Research randomly
			if upgradeStates.completed then
				player.giveItem(upgradedItem)
				checkResearchBonus()
				sb.logInfo("Upgraded Stats: \n"..sb.printJson(upgradedItem,1)) -- list all current bonuses being applied to the weapon for debug
			end
			--player.giveItem(upgradedItem)
			return upgradeStates
		end
	end
end

function applyBonusesEssence(mergeBuffer, itemConfig, categoryLower)
	--base DPS
	local baseDps=(mergeBuffer.baseDps) or itemConfig.config.baseDps
	if baseDps then
		mergeBuffer.baseDps = baseDps * (1 + (mergeBuffer.level/80) )	-- increase DPS a bit
	end

	--crit chance
	local critChance=(mergeBuffer.critChance) or itemConfig.config.critChance
	if critChance then
		local modifier=0.15
		if matchAny(categoryLower,{"rapier","katana","mace"}) then
			modifier=0.25
		end
		mergeBuffer.critChance = critChance + (mergeBuffer.level*modifier) -- increase Crit Chance
	end

	--crit bonus
	local critBonus=(mergeBuffer.critBonus) or itemConfig.config.critBonus
	if critBonus then
		local modifier=0.5
		if matchAny(categoryLower,{"rapier","katana","mace"}) then
			modifier=1.0
		end
		mergeBuffer.critBonus = critBonus + (mergeBuffer.level*modifier) -- increase Crit Chance
	end

	-- is it a shield?
	if (categoryLower == "shield") then
		local shieldBash=mergeBuffer.shieldBash or itemConfig.config.shieldBash
		if shieldBash then
			mergeBuffer.shieldBash=shieldBash+(mergeBuffer.level*0.5)
		end

		local shieldBashPush=mergeBuffer.shieldBashPush or itemConfig.config.shieldBashPush
		if shieldBashPush then
			mergeBuffer.shieldBashPush=shieldBashPush+(mergeBuffer.level*0.5)
		end

		local cooldownTime=mergeBuffer.cooldownTime or itemConfig.config.cooldownTime
		if cooldownTime then
			mergeBuffer.cooldownTime=cooldownTime*(1.0-(0.02*mergeBuffer.level))
		end

		local perfectBlockTime=mergeBuffer.perfectBlockTime or itemConfig.config.perfectBlockTime
		if perfectBlockTime then
			mergeBuffer.perfectBlockTime=perfectBlockTime*(1.0+(mergeBuffer.level*0.05))
		end

		local shieldEnergyBonus=mergeBuffer.shieldEnergyBonus or itemConfig.config.shieldEnergyBonus
		if shieldEnergyBonus then
			mergeBuffer.shieldEnergyBonus=shieldEnergyBonus*(1.0+(mergeBuffer.level*0.05))
		end

		local baseShieldHealth=mergeBuffer.baseShieldHealth or itemConfig.config.baseShieldHealth
		if baseShieldHealth then
			mergeBuffer.baseShieldHealth=baseShieldHealth*(1.0+(mergeBuffer.level*0.15))
		end
	end

	-- is it a staff or wand?
	if matchAny(categoryLower,{"staff","wand"}) then
		local baseDamageFactor=mergeBuffer.baseDamageFactor or itemConfig.config.baseDamageFactor
		if baseDamageFactor then
			mergeBuffer.baseDamageFactor=baseDamageFactor*(1.0+(mergeBuffer.level*0.075))
		end
	end

	-- magnorbs
	if (itemConfig.config.orbitRate) then
		local shieldKnockback=mergeBuffer.shieldKnockback or itemConfig.config.shieldKnockback
		if shieldKnockback then
			mergeBuffer.shieldKnockback=shieldKnockback+mergeBuffer.level
		end

		local shieldEnergyCost=mergeBuffer.shieldEnergyCost or itemConfig.config.shieldEnergyCost
		if shieldEnergyCost then
			mergeBuffer.shieldEnergyCost=shieldEnergyCost+mergeBuffer.level
		end

		local shieldHealth=mergeBuffer.shieldHealth or itemConfig.config.shieldHealth
		if shieldHealth then
			mergeBuffer.shieldHealth=shieldHealth+mergeBuffer.level
		end
	end

	-- boomerangs and other projectileParameters based things (magnorbs here too, chakrams)
	local projectileParameters=copy(mergeBuffer.projectileParameters or (itemConfig.config.projectileParameters and {}))
	if projectileParameters then
		if (projectileParameters.power or itemConfig.config.projectileParameters.power) then
			projectileParameters.power=(projectileParameters.power or itemConfig.config.projectileParameters.power)+(mergeBuffer.level/7)
		end
		if (projectileParameters.controlForce or itemConfig.config.projectileParameters.controlForce) then
			projectileParameters.controlForce=(projectileParameters.controlForce or itemConfig.config.projectileParameters.controlForce)+mergeBuffer.level
		end
		mergeBuffer.projectileParameters=projectileParameters
	end

	local primaryAbility=copy(mergeBuffer.primaryAbility or (itemConfig.config.primaryAbility and {}))
	if primaryAbility then
		if not matchAny(categoryLower,{"gun staff","sggunstaff"}) then --exclude Shellguard gunblades from this bit to not break their rotation
			-- bows
			if (categoryLower == "bow") then
				if (primaryAbility.drawTime or itemConfig.config.primaryAbility.drawTime) then
					primaryAbility.drawTime = (primaryAbility.drawTime or itemConfig.config.primaryAbility.drawTime) * (1 - (0.05*mergeBuffer.level))
				end
				local powerProjectileTime=primaryAbility.powerProjectileTime or itemConfig.config.primaryAbility.powerProjectileTime
				if type(powerProjectileTime)=="number" then
					powerProjectileTime = powerProjectileTime*(1-(0.05*mergeBuffer.level))
				elseif type(powerProjectileTime)=="table" then
					powerProjectileTime[1]=powerProjectileTime[1]*(1-(0.05*mergeBuffer.level))
					powerProjectileTime[2]=powerProjectileTime[2]*(1+(0.05*mergeBuffer.level))
				end
				-- FIXME: found by Luacheck: value of "powerProjectileTime" (that we just calculated above) is unused, was it supposed to be saved somewhere?

				primaryAbility.energyPerShot=primaryAbility.energyPerShot or itemConfig.config.primaryAbility.energyPerShot
				if (primaryAbility.energyPerShot or itemConfig.config.primaryAbility.energyPerShot) then
					primaryAbility.energyPerShot = (primaryAbility.energyPerShot or itemConfig.config.primaryAbility.energyPerShot) * math.max(0,(1-(mergeBuffer.level*0.05)))
				end
				if (primaryAbility.holdEnergyUsage or itemConfig.config.primaryAbility.holdEnergyUsage) then
					primaryAbility.holdEnergyUsage = (primaryAbility.holdEnergyUsage or itemConfig.config.primaryAbility.holdEnergyUsage) * math.max(0,1.0-(mergeBuffer.level*0.05))
				end
				if (primaryAbility.airborneBonus or itemConfig.config.primaryAbility.airborneBonus) then
					primaryAbility.airborneBonus = (primaryAbility.airborneBonus or itemConfig.config.primaryAbility.airborneBonus)*(1+(mergeBuffer.level*0.02))
				end
			end
			-- beams and miners
			if (primaryAbility.beamLength or itemConfig.config.primaryAbility.beamLength) then
				primaryAbility.beamLength=(primaryAbility.beamLength or itemConfig.config.primaryAbility.beamLength) + mergeBuffer.level
			end

			-- wands/staves
			if (primaryAbility.maxCastRange or itemConfig.config.primaryAbility.maxCastRange) then
				primaryAbility.maxCastRange = (primaryAbility.maxCastRange or itemConfig.config.primaryAbility.maxCastRange) + (mergeBuffer.level/4)
			end

			if (primaryAbility.energyCost or itemConfig.config.primaryAbility.energyCost) then
				primaryAbility.energyCost = (primaryAbility.energyCost or itemConfig.config.primaryAbility.energyCost) * math.max(0,1.0-(mergeBuffer.level*0.03))
			end

			-- does the item have a baseDps? if so, we increase the DPS slightly, but not if the weapon is a big hitter.
			local baseDps=(primaryAbility.baseDps or itemConfig.config.primaryAbility.baseDps)
			if (baseDps) and not (baseDps >=20) then
				primaryAbility.baseDps=baseDps*(1+(mergeBuffer.level/79))
			end
		else
			--gunblade upgrade data here
		end
		mergeBuffer.primaryAbility=primaryAbility
	end

	-- Can it STUN?
	if matchAny(categoryLower,{"hammer","mace","greataxe","quarterstaff"}) then
		local stunChance=mergeBuffer.stunChance or itemConfig.config.stunChance
		if stunChance then
			mergeBuffer.stunChance=stunChance+(mergeBuffer.level*0.5)
		end
	end
end

function applyBonusesModule(mergeBuffer, itemConfig, categoryLower)
	--crit chance
	local critChance=(mergeBuffer.critChance) or itemConfig.config.critChance
	if critChance then
		local modifier=0.1
		--[[if matchAny(categoryLower,{"rapier","katana","mace"}) then
			modifier=0.25
		end]]
		mergeBuffer.critChance = critChance + (mergeBuffer.level*modifier) -- increase Crit Chance
	end

	--crit chance
	local critBonus=(mergeBuffer.critBonus) or itemConfig.config.critBonus
	if critBonus then
		local modifier=0.25
		--[[if matchAny(categoryLower,{"rapier","katana","mace"}) then
			modifier=1.0
		end]]
		mergeBuffer.critBonus = critBonus + (mergeBuffer.level*modifier) -- increase Crit Chance
	end

	-- is it a shield?
	if (categoryLower == "shield") then
		local shieldBash=mergeBuffer.shieldBash or itemConfig.config.shieldBash
		if shieldBash then
			mergeBuffer.shieldBash=shieldBash+(mergeBuffer.level*0.25)
		end

		local cooldownTime=mergeBuffer.cooldownTime or itemConfig.config.cooldownTime
		if cooldownTime then
			mergeBuffer.cooldownTime=cooldownTime*(1.0-(0.02*mergeBuffer.level))
		end

		local perfectBlockTime=mergeBuffer.perfectBlockTime or itemConfig.config.perfectBlockTime
		if perfectBlockTime then
			mergeBuffer.perfectBlockTime=perfectBlockTime*(1.0+(mergeBuffer.level*0.03))
		end

		local shieldEnergyBonus=mergeBuffer.shieldEnergyBonus or itemConfig.config.shieldEnergyBonus
		if shieldEnergyBonus then
			mergeBuffer.shieldEnergyBonus=shieldEnergyBonus*(1.0+(mergeBuffer.level*0.05))
		end

		local baseShieldHealth=mergeBuffer.baseShieldHealth or itemConfig.config.baseShieldHealth
		if baseShieldHealth then
			mergeBuffer.baseShieldHealth=baseShieldHealth*(1.0+(mergeBuffer.level*0.05))
		end
	end

	-- magnorbs
	if (itemConfig.config.orbitRate) then
		local shieldKnockback=mergeBuffer.shieldKnockback or itemConfig.config.shieldKnockback
		if shieldKnockback then
			mergeBuffer.shieldKnockback=shieldKnockback+mergeBuffer.level
		end

		local shieldEnergyCost=mergeBuffer.shieldEnergyCost or itemConfig.config.shieldEnergyCost
		if shieldEnergyCost then
			mergeBuffer.shieldEnergyCost=shieldEnergyCost+mergeBuffer.level
		end

		local shieldHealth=mergeBuffer.shieldHealth or itemConfig.config.shieldHealth
		if shieldHealth then
			mergeBuffer.shieldHealth=shieldHealth+mergeBuffer.level
		end
	end

	-- is it a staff or wand?
	if matchAny(categoryLower,{"staff","wand"}) then
		local baseDamageFactor=mergeBuffer.baseDamageFactor or itemConfig.config.baseDamageFactor
		if baseDamageFactor then
			mergeBuffer.baseDamageFactor=baseDamageFactor*(1.0+(mergeBuffer.level*0.05))
		end
	end

	-- boomerangs and other projectileParameters based things (magnorbs here too, chakrams)
	local projectileParameters=copy(mergeBuffer.projectileParameters or (itemConfig.config.projectileParameters and {}))
	if projectileParameters then
		if (projectileParameters.controlForce or itemConfig.config.projectileParameters.controlForce) then
			projectileParameters.controlForce=(projectileParameters.controlForce or itemConfig.config.projectileParameters.controlForce)+mergeBuffer.level
		end
		mergeBuffer.projectileParameters=projectileParameters
	end

	local primaryAbility=copy(mergeBuffer.primaryAbility or (itemConfig.config.primaryAbility and {}))
	if primaryAbility then
		if not matchAny(categoryLower,{"gun staff","sggunstaff"}) then --exclude Shellguard gunblades from this bit to not break their rotation
			-- beams and miners
			if (primaryAbility.beamLength or itemConfig.config.primaryAbility.beamLength) then
				primaryAbility.beamLength=(primaryAbility.beamLength or itemConfig.config.primaryAbility.beamLength) + mergeBuffer.level
			end

			-- wands/staves
			if (primaryAbility.maxCastRange or itemConfig.config.primaryAbility.maxCastRange) then
				primaryAbility.maxCastRange = (primaryAbility.maxCastRange or itemConfig.config.primaryAbility.maxCastRange) + (mergeBuffer.level/4)
			end

			if (primaryAbility.energyCost or itemConfig.config.primaryAbility.energyCost) then
				primaryAbility.energyCost = (primaryAbility.energyCost or itemConfig.config.primaryAbility.energyCost) * math.max(0,1.0-(mergeBuffer.level*0.03))
			end

			-- does the item have a baseDps? if so, we increase the DPS slightly, but not if the weapon is a big hitter.
			local baseDps=primaryAbility.baseDps or itemConfig.config.primaryAbility.baseDps
			if (baseDps) and not (baseDps >=20) then
				primaryAbility.baseDps=baseDps*(1+(mergeBuffer.level/79))
			end
		else
			--gunblade upgrade data here
		end
		mergeBuffer.primaryAbility=primaryAbility
	end

	-- Can it STUN?
	if matchAny(categoryLower,{"hammer","mace","greataxe","quarterstaff"}) then
		local stunChance=mergeBuffer.stunChance or itemConfig.config.stunChance
		if stunChance then
			mergeBuffer.stunChance=stunChance+(mergeBuffer.level*0.5)
		end
	end
end

local oldCompare=compare
function compare(t1,t2)
	local pass,result=pcall(oldCompare,t1,t2)
	if pass then
		return result
	else
		criticalError()
	end
end

function criticalError()
	--fatal error, essentially. this can happen with certain items like the massive spawned in holo ruler thing. we're going to just disable the entire UI and display an informative warning.
	widget.setVisible("essenceCostDescription",true)
	widget.setVisible("upgradeTargetLabel",false)
	widget.setVisible("upgradeTargetText",false)
	widget.setVisible("itemScrollArea",false)
	widget.setVisible("essenceCost",true)
	widget.setVisible("warningLabel",true)
	widget.setVisible("emptyLabel",false)
	widget.setVisible("btnUpgrade",false)
	widget.setText("essenceCostDescription","^red;UI OVER-LOADED")
	widget.setText("essenceCost","^yellow;Remove some items from inventory.")
	widget.setText("warningLabel","^red;CRITICAL ERROR")
	script.setUpdateDelta(0)
	error("Your inventory has too much item data to parse. This upgrade UI can't handle that.")
end

function deepSizeOf(arg)
	if type(arg)~="table" then return 1 end
	local i=0
	for _,value in pairs(arg) do
		if type(value)~="table" then i=i+1
		else i=i+deepSizeOf(value)
		end
	end
	return(i)
end
