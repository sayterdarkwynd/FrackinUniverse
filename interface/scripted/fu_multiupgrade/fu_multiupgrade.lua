require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/furesearchGenerators.lua"

local cosmeticList={legwear=true,chestwear=true,headwear=true,backwear=true}
local armorList={legarmour=true,chestarmour=true,headarmour=true,enviroProtectionPack=true}
local cosmeticSlotList={"headCosmetic", "chestCosmetic", "legsCosmetic", "backCosmetic"}
local armorSlotList={"head", "chest", "legs", "back"}

function init()
	self.itemList = "itemScrollArea.itemList"
	self.weaponUpgradeLevel = 6
	self.toolUpgradeLevel = 20
	self.upgradableItems = {}
	self.selectedItem = nil
	populateItemList()
	widget.setText("warningLabel","")
end

function update(dt)
	if lockoutTimer then lockoutTimer = math.max(0,lockoutTimer-dt) end
	populateItemList()
	if lockoutTimer and lockoutTimer > 0 then return end
	itemSelected()
end

function upgradeCost(itemConfig,itemType)
	if itemConfig == nil then return 0 end
	local newValue = 0

	if itemType=="weapon" then
		newValue=(itemConfig.parameters.level or itemConfig.config.level) or 1--cost is current level in upgrade modules
	elseif itemType=="tool" then
		itemConfig.config.upmod = itemConfig.config.upmod or 1
		newValue = (root.evalFunction("minerModuleValue", itemConfig.parameters.level or itemConfig.config.level or 1) *3) * itemConfig.config.upmod
	end
	return math.floor(newValue)
end

function populateItemList(forceRepop)
	local upgradeableWeaponItems = player.itemsWithTag("upgradeableWeapon")
	local upgradeableToolItems = player.itemsWithTag("upgradeableTool")
	local upgradableItems={}

	for i = 1, #upgradeableWeaponItems do
		local monkeys=deepSizeOf(upgradeableWeaponItems[i])
		if monkeys <=250 then
			upgradeableWeaponItems[i].count = 1
			table.insert(upgradableItems,{itemData=upgradeableWeaponItems[i],itemType="weapon"})
		end
	end

	for i = 1, #upgradeableToolItems do
		local monkeys=deepSizeOf(upgradeableToolItems[i])
		if monkeys <=250 then
			upgradeableToolItems[i].count = 1
			table.insert(upgradableItems,{itemData=upgradeableToolItems[i],itemType="tool"})
		end
	end

	widget.setVisible("emptyLabel", #upgradableItems == 0)

	local upgrademodules = player.hasCountOfItem("upgrademodule")
	local manipulatormodules = player.hasCountOfItem("manipulatormodule")

	local itemsCompare=compare(upgradableItems, self.upgradableItems)

	if forceRepop or not itemsCompare then
		widget.clearListItems(self.itemList)
		widget.setButtonEnabled("btnUpgrade", false)
		self.upgradableItems = upgradableItems
		--widget.clearListItems(self.itemList)
		--widget.setButtonEnabled("btnUpgrade", false)

		for i, item in pairs(self.upgradableItems) do
			local config = root.itemConfig(item.itemData)
			local entryLevelMax=(item.itemType=="weapon" and self.weaponUpgradeLevel) or (item.itemType=="tool" and self.toolUpgradeLevel)
			if (config.parameters.level or config.config.level or 1) < entryLevelMax then
				local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
				local name = config.parameters.shortdescription or config.config.shortdescription

				widget.setText(string.format("%s.itemName", listItem), name)
				widget.setItemSlotItem(string.format("%s.itemIcon", listItem), item.itemData)

				local price = upgradeCost(config,item.itemType)
				widget.setData(listItem, { index = i, price = price,itemType = item.itemType })

				local priceVar = (item.itemType=="weapon" and upgrademodules) or (item.itemType=="tool" and manipulatormodules) or 0
				widget.setVisible(string.format("%s.unavailableoverlay", listItem), price > priceVar)
			end
		end

		self.selectedItem = nil
		showItem(nil)
	end
end

function showItem(item,price,itemType)
	local enableButton=false
	local isWorn=checkWorn(item)

	if itemType=="weapon" then
		enableButton=showWeapon(item,price) and not isWorn
	elseif itemType=="tool" then
		enableButton=showTool(item,price) and not isWorn
	else
		widget.setText("essenceCost", string.format("0 / --"))
	end

	widget.setText("warningLabel",isWorn and "Error: "..isWorn or "")

	widget.setVisible("upgradeIcon",itemType=="weapon")
	widget.setVisible("manipIcon",itemType=="tool")
	widget.setButtonEnabled("btnUpgrade", enableButton)
end

function getSelectedItem()
	if not self.selectedItem then return end
	return self.upgradableItems[widget.getData(string.format("%s.%s", self.itemList, self.selectedItem)).index].itemData
end

function checkWorn(item)
	if not item then return "no item selected" end
	--sb.logInfo("item: %s",item)
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
	if isCosmeticArmor then
		for _,slot in pairs(cosmeticSlotList) do
			local compTo=player.equippedItem(slot)
			if compare(compTo,item) then return "equipped in cosmetic slot" end
		end
	elseif isArmor then
		for _,slot in pairs(armorSlotList) do
			local compTo=player.equippedItem(slot)
			if compare(compTo,item) then return "equipped in armor slot" end
		end
	end
	if compare(swapSlotItem,item) then return "held by mouse" end
	return false
end

function showWeapon(item, price)
	local upgradeModules = player.hasCountOfItem("upgrademodule", true)
	local enableButton = false

	if item then
		enableButton = upgradeModules >= price
		local directive = enableButton and "^green;" or "^red;"
		widget.setText("essenceCost", string.format("%s%s / %s", directive, upgradeModules, price))
	--else
		--widget.setText("essenceCost", string.format("%s / --", upgradeModules))
	end
	--widget.setButtonEnabled("btnUpgrade", enableButton)
	return enableButton
end

function showTool(item, price)
	local playerModule = player.hasCountOfItem("manipulatormodule", true)
	local enableButton = false

	if item then
		enableButton = playerModule >= price
		local directive = enableButton and "^green;" or "^red;"
		widget.setText("essenceCost", string.format("%s%s / %s", directive, playerModule, price))
	else
		widget.setText("essenceCost", string.format("%s / --", playerModule))
	end

	return enableButton
end

function itemSelected()
	local listItem = widget.getListSelected(self.itemList)
	self.selectedItem = listItem

	if listItem then
		local listItem = widget.getData(string.format("%s.%s", self.itemList, listItem))
		local localItem = self.upgradableItems[listItem.index]
		showItem(localItem.itemData,listItem.price,localItem.itemType)
	end
end

function doUpgrade()
	if lockoutTimer and lockoutTimer > 0 then return end
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
			local pass,result=pcall(upgradeWeapon,upgradeItemInfo.itemData,selectedData.price)
			if not pass then
				player.giveItem(upgradeItemInfo.itemData)
				sb.logInfo("Upgrade (weapon/armor) failed: %s",result)
			end
		elseif upgradeItemInfo.itemType=="tool" then
			local pass,result=pcall(upgradeTool,upgradeItemInfo.itemData,selectedData.price)
			if not pass then
				player.giveItem(upgradeItemInfo.itemData)
				sb.logInfo("Upgrade (tool) failed: %s",result)
			end
		end

		populateItemList(true)
	end
	lockoutTimer=0.1
	widget.setButtonEnabled("btnUpgrade", false)
end

function highestRarity(rarity2,rarity1)
	local t={common=1,uncommon=2,rare=3,legendary=4,essential=5}
	rarity1=string.lower(rarity1 or "")
	rarity2=string.lower(rarity2 or "")
	if (t[rarity1] or 0)> (t[rarity2] or 0) then return rarity1 else return rarity2 end
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

function upgradeWeapon(upgradeItem,price)
	if upgradeItem then
		local consumedItem = player.consumeItem(upgradeItem, false, true)
		if consumedItem then
			local consumedCurrency = player.consumeItem({name = "upgrademodule", count = price}, false, true)
			local upgradedItem = copy(consumedItem)
			if consumedCurrency then
				local mergeBuffer={}
				local itemConfig = root.itemConfig(upgradedItem)
				local defaultLvl = (itemConfig.config.level or 1)
				local categoryLower=string.lower(mergeBuffer.category or itemConfig.parameters.category or itemConfig.config.category or "")

				mergeBuffer.level = (itemConfig.parameters.level or itemConfig.config.level or 1) + 1

				local oldRarity=(itemConfig.parameters and itemConfig.parameters.rarity) or (itemConfig.config and itemConfig.config.rarity)
				mergeBuffer.rarity=oldRarity

				if (itemConfig.config.upgradeParametersTricorder) and (mergeBuffer.level > 1) then
					mergeBuffer = util.mergeTable(copy(mergeBuffer), copy(itemConfig.config.upgradeParametersTricorder))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
					oldRarity=mergeBuffer.rarity
				end

				if (itemConfig.config.upgradeParameters) and (mergeBuffer.level > math.max(defaultLvl, 4)) then
					mergeBuffer = util.mergeTable(copy(mergeBuffer), copy(itemConfig.config.upgradeParameters))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
					oldRarity=mergeBuffer.rarity
				end

				if (itemConfig.config.upgradeParameters2) and (mergeBuffer.level > math.max(defaultLvl+1, 5)) then
					mergeBuffer = util.mergeTable(copy(mergeBuffer), copy(itemConfig.config.upgradeParameters2))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
					oldRarity=mergeBuffer.rarity
				end
				if (itemConfig.config.upgradeParameters3) and (mergeBuffer.level > math.max(defaultLvl+2, 6)) then
					mergeBuffer = util.mergeTable(copy(mergeBuffer), copy(itemConfig.config.upgradeParameters3))
					mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
					oldRarity=mergeBuffer.rarity
				end

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

				-- set Rarity
				if mergeBuffer.level == 4 then
					mergeBuffer.rarity = highestRarity("uncommon",mergeBuffer.rarity)
				elseif mergeBuffer.level == 5 then
					mergeBuffer.rarity = highestRarity("rare",mergeBuffer.rarity)
				--[[elseif mergeBuffer.level == 6 then
					mergeBuffer.rarity = highestRarity("legendary",mergeBuffer.rarity)
				elseif mergeBuffer.level >= 7 then
					mergeBuffer.rarity = highestRarity("essential",mergeBuffer.rarity)]]
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
					projectileParameters.controlForce=projectileParameters.controlForce or itemConfig.config.projectileParameters.controlForce
					if projectileParameters.controlForce then
						projectileParameters.controlForce=projectileParameters.controlForce+mergeBuffer.level
					end
					mergeBuffer.projectileParameters=projectileParameters
				end

				local primaryAbility=copy(mergeBuffer.primaryAbility or (itemConfig.config.primaryAbility and {}))
				if primaryAbility then
					if not matchAny(categoryLower,{"gun staff","sggunstaff"}) then --exclude Shellguard gunblades from this bit to not break their rotation
						-- beams and miners
						primaryAbility.beamLength=primaryAbility.beamLength or itemConfig.config.primaryAbility.beamLength
						if (primaryAbility.beamLength) then
							primaryAbility.beamLength=primaryAbility.beamLength + mergeBuffer.level
						end

						-- wands/staves
						primaryAbility.maxCastRange=primaryAbility.maxCastRange or itemConfig.config.primaryAbility.maxCastRange
						if (primaryAbility.maxCastRange) then
							primaryAbility.maxCastRange = primaryAbility.maxCastRange + (mergeBuffer.level/4)
						end

						primaryAbility.energyCost=primaryAbility.energyCost or itemConfig.config.primaryAbility.energyCost
						if (itemConfig.config.primaryAbility.energyCost) then
							primaryAbility.energyCost = primaryAbility.energyCost * math.max(0,1.0-(mergeBuffer.level*0.03))
						end

						-- does the item have a baseDps? if so, we increase the DPS slightly, but not if the weapon is a big hitter.
						primaryAbility.baseDps=primaryAbility.baseDps or itemConfig.config.primaryAbility.baseDps
						if (primaryAbility.baseDps) and not (primaryAbility.baseDps >=20) then
							primaryAbility.baseDps=primaryAbility.baseDps*(1+(mergeBuffer.level/79))
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
				mergeBuffer.rarity=highestRarity(mergeBuffer.rarity,oldRarity)
				upgradedItem.parameters=util.mergeTable(copy(upgradedItem.parameters),copy(mergeBuffer))

				-- check if player gets Research randomly
				checkResearchBonus()
				player.giveItem(upgradedItem)
			end
		end
	end
end

function upgradeTool(upgradeItem,price)
	if upgradeItem then
		local consumedItem = player.consumeItem(upgradeItem, false, true)
		if consumedItem then
			local consumedCurrency = player.consumeItem({name = "manipulatormodule", count = price}, false, true)
			--local consumedCurrency = player.consumeCurrency("fuscienceresource", selectedData.price)
			local upgradedItem = copy(consumedItem)
			if consumedCurrency then
				local itemConfig = root.itemConfig(upgradedItem)
				local oldRarity=(itemConfig.parameters and itemConfig.parameters.rarity) or (itemConfig.config and itemConfig.config.rarity)
				upgradedItem.parameters.level = (itemConfig.parameters.level or itemConfig.config.level or 1) + 1

				-- set Rarity
				if upgradedItem.parameters.level ==3 then
					upgradedItem.parameters.rarity = highestRarity("uncommon",oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif upgradedItem.parameters.level == 5 then
					upgradedItem.parameters.rarity = highestRarity("rare",oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif upgradedItem.parameters.level == 7 then
					upgradedItem.parameters.rarity = highestRarity("legendary",oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level >= 8) and (itemHasTag(itemConfig,"mininglaser")) then
					upgradedItem.parameters.rarity = highestRarity("essential",oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				end

				upgradedItem.parameters.primaryAbility = {}

				-- check item types here
				if not (upgradedItem.parameters.upmod) then
					upgradedItem.parameters.upmod = 1
				end

				if (upgradedItem.parameters.level) <= 2 and itemConfig.config.upgradeParameters then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level) == 3 and itemConfig.config.upgradeParameters2 then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level) == 4 and itemConfig.config.upgradeParameters3 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "parasol") then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters3)
					upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 1.5
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level) == 5 and itemConfig.config.upgradeParameters4 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator") and not (itemConfig.config.category == "parasol") then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters4)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level) == 6 and itemConfig.config.upgradeParameters5 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator") and not (itemConfig.config.category == "parasol") then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters5)
					upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 2
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level) == 7 and itemConfig.config.upgradeParameters6 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator")	and not (itemConfig.config.category == "parasol") and not (itemConfig.config.category == "translocator") then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters6)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level) == 8 and itemConfig.config.upgradeParameters7 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator")	and not (itemConfig.config.category == "parasol") and not (itemConfig.config.category == "translocator") then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters7)
					upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 2.5
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level) > 8 and itemConfig.config.upgradeParameters8 and itemHasTag(itemConfig,"mininglaser") then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters8)
					upgradedItem.parameters.primaryAbility.beamLength= 30 + ( upgradedItem.parameters.level + 1 )
					upgradedItem.parameters.primaryAbility.energyUsage= 6 + ( upgradedItem.parameters.level /10 )
					upgradedItem.parameters.primaryAbility.baseDps = itemConfig.config.primaryAbility.baseDps + ( upgradedItem.parameters.level /10 )
					upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 3
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (upgradedItem.parameters.level) > 8 and itemConfig.config.upgradeParameters8 and (itemConfig.config.category == "bugnet") then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters8)
					upgradedItem.parameters.primaryAbility.energyUsage= 1 + ( upgradedItem.parameters.level /20 )
					upgradedItem.parameters.primaryAbility.baseDps = itemConfig.config.primaryAbility.baseDps + ( upgradedItem.parameters.level /10 )
					upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 3
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				end

				if (itemConfig.config.category == "repairgun") and (upgradedItem.parameters.level) > 8 and itemConfig.config.upgradeParameters8 then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters8)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
					upgradedItem.parameters.primaryAbility.projectileParameters.restoreBase= (upgradedItem.parameters.level) + 3
					upgradedItem.parameters.primaryAbility.projectileParameters.speed= (upgradedItem.parameters.level)+1
					upgradedItem.parameters.primaryAbility.energyUsage= 10 + ( upgradedItem.parameters.level /10 )
					-- catch leftovers
				elseif (itemConfig.config.category == "detector") and (upgradedItem.parameters.level) >=8 then -- ore detectors and cave detectors
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters8)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
					upgradedItem.parameters.pingRange= upgradedItem.parameters.pingRange + 1
					upgradedItem.parameters.pingDuration= upgradedItem.parameters.pingDuration + 0.15
					upgradedItem.parameters.pingCooldown= upgradedItem.parameters.pingCooldown - 0.05
				elseif (itemConfig.config.category == "parasol") and (upgradedItem.parameters.level) >=3 then -- parasol
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
					upgradedItem.parameters.level = 20
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (itemConfig.config.category == "translocator") and (upgradedItem.parameters.level) >=5 then -- translocator
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters4)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
					upgradedItem.parameters.level = 20
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (itemConfig.config.category == "hookshot") and (upgradedItem.parameters.level) >=3 then -- hookshots
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
					upgradedItem.parameters.level = 20
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				elseif (itemConfig.config.category == "relocator") and (upgradedItem.parameters.level) >=4 then -- relocators
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters3)
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
					upgradedItem.parameters.level = 20
					upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
					oldRarity=upgradedItem.parameters.rarity
				end

			end
			upgradedItem.parameters.rarity=highestRarity(upgradedItem.parameters.rarity,oldRarity)
			player.giveItem(upgradedItem)
			checkResearchBonus()
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
	widget.setVisible("itemScrollArea",false)
	widget.setVisible("manipIcon",false)
	widget.setVisible("upgradeIcon",false)
	widget.setVisible("essenceCost",true)
	widget.setVisible("warningLabel",true)
	widget.setVisible("emptyLabel",false)
	widget.setVisible("btnUpgrade",false)
	widget.setText("essenceCostDescription","^red;HEAVILY OVER-MODDED ITEM")
	widget.setText("essenceCost","^yellow;Find it. Remove it.")
	widget.setText("warningLabel","^red;CRITICAL ERROR: ID10T")
	script.setUpdateDelta(0)
	error("You have a heavily overloaded item. This upgrade UI can't handle those. Items like the holographic ruler, for example.")
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
