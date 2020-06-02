require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/researchGenerators.lua"

function init()
	self.itemList = "itemScrollArea.itemList"
	self.weaponUpgradeLevel = 6
	self.toolUpgradeLevel = 20
	self.upgradableItems = {}
	self.selectedItem = nil
	populateItemList()
end

function update(dt)
	populateItemList()
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
		upgradeableWeaponItems[i].count = 1
		table.insert(upgradableItems,{itemData=upgradeableWeaponItems[i],itemType="weapon"})
	end
	
	for i = 1, #upgradeableToolItems do
		upgradeableToolItems[i].count = 1
		table.insert(upgradableItems,{itemData=upgradeableToolItems[i],itemType="tool"})
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
	if itemType=="weapon" then
		enableButton=showWeapon(item,price)
	elseif itemType=="tool" then
		enableButton=showTool(item,price)
	else
		widget.setText("essenceCost", string.format("0 / --"))
	end
	
	widget.setVisible("upgradeIcon",itemType=="weapon")
	widget.setVisible("manipIcon",itemType=="tool")
	widget.setButtonEnabled("btnUpgrade", enableButton)
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
  local playerModule =  player.hasCountOfItem("manipulatormodule", true)
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

--[[
function isArmor()
	if (upgradedItem.parameters.category == "legarmor") or (upgradedItem.parameters.category == "chestarmor") or (upgradedItem.parameters.category == "headarmor") then
		isArmorSet = 1
		return isArmorSet
	end
end]]

function doUpgrade()
	if self.selectedItem then

		local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))
		local upgradeItemInfo = self.upgradableItems[selectedData.index]
		if upgradeItemInfo.itemType=="weapon" then
			upgradeWeapon(upgradeItemInfo.itemData,selectedData.price)
		elseif upgradeItemInfo.itemType=="tool" then
			upgradeTool(upgradeItemInfo.itemData,selectedData.price)
		end
		
		
		populateItemList(true)
	end
end

function upgradeWeapon(upgradeItem,price)
	if upgradeItem then
		local consumedItem = player.consumeItem(upgradeItem, false, true)
		if consumedItem then
			local consumedCurrency = player.consumeItem({name = "upgrademodule", count = price}, false, true) 
			local upgradedItem = copy(consumedItem)
			if consumedCurrency then
				
				local itemConfig = root.itemConfig(upgradedItem)  
				self.baseValueMod = itemConfig.config.level or 1 -- store the original level in case we need it for calculations
				
				upgradedItem.parameters.level = (itemConfig.parameters.level or itemConfig.config.level or 1) + 1
				
				upgradedItem.parameters.critChance = (itemConfig.parameters.critChance or itemConfig.config.critChance or 1) + 0.1  -- increase Crit Chance
				upgradedItem.parameters.critBonus = (itemConfig.parameters.critBonus or itemConfig.config.critBonus or 1) + 0.25     -- increase Crit Damage 

				-- set Rarity
				if upgradedItem.parameters.level ==4 then
					upgradedItem.parameters.rarity = "uncommon"
				elseif upgradedItem.parameters.level == 5 then
					upgradedItem.parameters.rarity = "rare"	   
				end

				-- is it a shield?
				if (itemConfig.config.category == "shield") then
					upgradedItem.parameters.shieldBash = (itemConfig.parameters.shieldBash or itemConfig.config.shieldBash or 1) + 0.25 + self.baseValueMod  
					upgradedItem.parameters.shieldBashPush = (itemConfig.parameters.shieldBashPush or itemConfig.config.shieldBashPush or 1) + 0.25  
					
					if upgradedItem.parameters.cooldownTime then
						upgradedItem.parameters.cooldownTime = (itemConfig.parameters.cooldownTime or itemConfig.config.cooldownTime or 1) * 0.98 
					end
					
					if upgradedItem.parameters.perfectBlockTime then
						upgradedItem.parameters.perfectBlockTime = (itemConfig.parameters.perfectBlockTime or itemConfig.config.perfectBlockTime or 1) * 1.03
					end
					if upgradedItem.parameters.shieldEnergyBonus then
						upgradedItem.parameters.shieldEnergyBonus = (itemConfig.parameters.shieldEnergyBonus or itemConfig.config.shieldEnergyBonus or 1) * 1.05
					end						
					if upgradedItem.parameters.baseShieldHealth then
						upgradedItem.parameters.baseShieldHealth = (itemConfig.parameters.baseShieldHealth or itemConfig.config.baseShieldHealth or 1) * 1.05
					end
				end
				
				upgradedItem.parameters.primaryAbility = {}   
				
				-- magnorbs
				if (upgradedItem.parameters.orbitRate) then
					upgradedItem.parameters.shieldKnockback = (itemConfig.parameters.shieldKnockback or itemConfig.config.shieldKnockback or 1) + 1 
					upgradedItem.parameters.shieldEnergyCost = (itemConfig.parameters.shieldEnergyCost or itemConfig.config.shieldEnergyCost or 1) + 1 
					upgradedItem.parameters.shieldHealth = (itemConfig.parameters.shieldHealth or itemConfig.config.shieldHealth or 1) + 1 
				end 
				--staff
				if (itemConfig.config.category == "staff") or (itemConfig.config.category == "wand") then
					upgradedItem.parameters.primaryAbility = {} 
					if (itemConfig.config.baseDamageFactor) then
						upgradedItem.parameters.baseDamageFactor = (itemConfig.parameters.baseDamageFactor or itemConfig.config.baseDamageFactor or 1) * 1.05 
					end	    
				end 
				-- boomerangs and other projectileParameters based things (magnorbs here too , chakrams)
				if (upgradedItem.parameters.projectileParameters) then   
					upgradedItem.parameters.projectileParameters = { 
						controlForce = itemConfig.config.primaryAbility.controlForce + (upgradedItem.parameters.level)
					}
				end   

				if (itemConfig.config.primaryAbility) then	 
					
					-- beams and miners
					if (itemConfig.config.primaryAbility.beamLength) then
						upgradedItem.parameters.primaryAbility.beamLength= itemConfig.config.primaryAbility.beamLength + upgradedItem.parameters.level 
					end
					
					-- wands/staves	
					if (itemConfig.config.primaryAbility.maxCastRange) then
						upgradedItem.parameters.primaryAbility = {
							maxCastRange = itemConfig.config.primaryAbility.maxCastRange + (upgradedItem.parameters.level/4)
						}
					end
					
					if (itemConfig.config.primaryAbility.energyCost) then
						upgradedItem.parameters.primaryAbility = {
							energyCost = itemConfig.config.primaryAbility.energyCost - (upgradedItem.parameters.level/3)
						}
					end

					-- Can it STUN?	
					if (itemConfig.config.category == "hammer") or (itemConfig.config.category == "mace") or (itemConfig.config.category == "greataxe") or (itemConfig.config.category == "quarterstaff") then
						upgradedItem.parameters.stunChance = (itemConfig.parameters.stunChance or itemConfig.config.stunChance or 1) + 0.5 + self.baseValueMod                    
					end
				end				
				
				
				if (itemConfig.config.improvedParameters)  and (upgradedItem.parameters.level) > 3 then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.improvedParameters)
				end					
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
		  upgradedItem.parameters.level = (itemConfig.parameters.level or itemConfig.config.level or 1) + 1

	 -- set Rarity
	 if upgradedItem.parameters.level ==3 then
	   upgradedItem.parameters.rarity = "uncommon"
	 elseif upgradedItem.parameters.level == 5 then
	   upgradedItem.parameters.rarity = "rare"
	 elseif upgradedItem.parameters.level == 7 then
	   upgradedItem.parameters.rarity = "legendary"
	 elseif upgradedItem.parameters.level >= 8 then
	   upgradedItem.parameters.rarity = "essential"	   
	 end
	 
			  
          upgradedItem.parameters.primaryAbility = {}  
          
        -- check item types here
        if not (upgradedItem.parameters.upmod) then 
          upgradedItem.parameters.upmod = 1
        end
        
	if (upgradedItem.parameters.level) <= 2 and itemConfig.config.upgradeParameters then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters)
	elseif (upgradedItem.parameters.level) == 3 and itemConfig.config.upgradeParameters2 then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
	elseif (upgradedItem.parameters.level) == 4 and itemConfig.config.upgradeParameters3 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "parasol") then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters3)
		upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 1.5
	elseif (upgradedItem.parameters.level) == 5 and itemConfig.config.upgradeParameters4 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator") and not (itemConfig.config.category == "parasol") then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters4)
	elseif (upgradedItem.parameters.level) == 6 and itemConfig.config.upgradeParameters5 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator") and not (itemConfig.config.category == "parasol") then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters5)
		upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 2
	elseif (upgradedItem.parameters.level) == 7 and itemConfig.config.upgradeParameters6 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator")  and not (itemConfig.config.category == "parasol") and not (itemConfig.config.category == "translocator") then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters6)
	elseif (upgradedItem.parameters.level) == 8 and itemConfig.config.upgradeParameters7 and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator")  and not (itemConfig.config.category == "parasol") and not (itemConfig.config.category == "translocator") then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters7)
		upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 2.5
	elseif (upgradedItem.parameters.level) > 8 and itemConfig.config.upgradeParameters8 and not (itemConfig.config.category == "bugnet") and not (itemConfig.config.category == "hookshot") and not (itemConfig.config.category == "relocator")  and not (itemConfig.config.category == "parasol") and not (itemConfig.config.category == "translocator") and not (itemConfig.config.category == "detector") then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters8)
		upgradedItem.parameters.primaryAbility.beamLength= 30 + ( upgradedItem.parameters.level + 1 )
		upgradedItem.parameters.primaryAbility.energyUsage= 6 + ( upgradedItem.parameters.level /10 )
		upgradedItem.parameters.primaryAbility.baseDps = itemConfig.config.primaryAbility.baseDps + ( upgradedItem.parameters.level /10 )
		upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 3
		upgradedItem.parameters.rarity = "legendary"
	elseif (upgradedItem.parameters.level) > 8 and itemConfig.config.upgradeParameters8 and (itemConfig.config.category == "bugnet") then
		upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters8)
		upgradedItem.parameters.primaryAbility.energyUsage= 1 + ( upgradedItem.parameters.level /20 )
		upgradedItem.parameters.primaryAbility.baseDps = itemConfig.config.primaryAbility.baseDps + ( upgradedItem.parameters.level /10 )
		upgradedItem.parameters.upmod= upgradedItem.parameters.upmod + 0.5 or 3
		upgradedItem.parameters.rarity = "legendary"
	end
	
	  if (itemConfig.config.category == "repairgun") and (upgradedItem.parameters.level) > 8 and itemConfig.config.upgradeParameters8 then
		  upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters8)
		  upgradedItem.parameters.primaryAbility.projectileParameters.restoreBase= (upgradedItem.parameters.level) + 3
		  upgradedItem.parameters.primaryAbility.projectileParameters.speed= (upgradedItem.parameters.level)+1
		  upgradedItem.parameters.primaryAbility.energyUsage= 10 + ( upgradedItem.parameters.level /10 )
	  -- catch leftovers  
	  elseif (itemConfig.config.category == "detector") and (upgradedItem.parameters.level) >=8 then -- ore detectors and cave detectors
		  upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters8)
		  upgradedItem.parameters.pingRange= upgradedItem.parameters.pingRange + 1
		  upgradedItem.parameters.pingDuration= upgradedItem.parameters.pingDuration + 0.15
		  upgradedItem.parameters.pingCooldown= upgradedItem.parameters.pingCooldown - 0.05  
	  elseif (itemConfig.config.category == "parasol") and (upgradedItem.parameters.level) >=3 then -- parasol
		  upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
		  upgradedItem.parameters.level = 20	
		  upgradedItem.parameters.rarity = "legendary"	
	  elseif (itemConfig.config.category == "translocator") and (upgradedItem.parameters.level) >=5 then -- translocator
		  upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters4)
		  upgradedItem.parameters.level = 20	
		  upgradedItem.parameters.rarity = "legendary"	
	  elseif (itemConfig.config.category == "hookshot") and (upgradedItem.parameters.level) >=3 then -- hookshots
		  upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
		  upgradedItem.parameters.level = 20	
		  upgradedItem.parameters.rarity = "legendary"	
	  elseif (itemConfig.config.category == "relocator") and (upgradedItem.parameters.level) >=4 then -- relocators
		  upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters3)
		  upgradedItem.parameters.level = 20
		  upgradedItem.parameters.rarity = "legendary"	
	  end 
	  
        end
        player.giveItem(upgradedItem)
	checkResearchBonus()
      end
    end
end