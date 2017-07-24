require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.itemList = "itemScrollArea.itemList"

  self.upgradeLevel = 20

  self.upgradeableWeaponItems = {}
  self.selectedItem = nil
  populateItemList()
end

function update(dt)
  populateItemList()
end

function upgradeCost(itemConfig)
  if itemConfig == nil then return 0 end

  local prevValue = root.evalFunction("minerModuleValue", itemConfig.parameters.level or itemConfig.config.level or 1) *2
  local newValue = (root.evalFunction("minerModuleValue", self.upgradeLevel) * ( (itemConfig.parameters.level or itemConfig.config.level or 1)/25) *2)
  return math.floor(prevValue)
end


function populateItemList(forceRepop)
  local upgradeableWeaponItems = player.itemsWithTag("mininglaser")
  for i = 1, #upgradeableWeaponItems do
    upgradeableWeaponItems[i].count = 1
  end

  widget.setVisible("emptyLabel", #upgradeableWeaponItems == 0)

  local playerModule = player.hasCountOfItem("manipulatormodule", true)

  if forceRepop or not compare(upgradeableWeaponItems, self.upgradeableWeaponItems) then
    self.upgradeableWeaponItems = upgradeableWeaponItems
    widget.clearListItems(self.itemList)
    widget.setButtonEnabled("btnUpgrade", false)

    for i, item in pairs(self.upgradeableWeaponItems) do
      local config = root.itemConfig(item)

      if (config.parameters.level or config.config.level or 1) < self.upgradeLevel then
        local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
        local name = config.config.shortdescription

        widget.setText(string.format("%s.itemName", listItem), name)
        widget.setItemSlotItem(string.format("%s.itemIcon", listItem), item)

        local price = upgradeCost(config)
        widget.setData(listItem,
          {
            index = i,
            price = price
          })

        widget.setVisible(string.format("%s.unavailableoverlay", listItem), price > playerModule)
      end
    end

    self.selectedItem = nil
    showWeapon(nil)
  end
end

function showWeapon(item, price)
  local playerModule =  player.hasCountOfItem("manipulatormodule", true)
  local enableButton = false

  if item then
    enableButton = playerModule >= price
    local directive = enableButton and "^green;" or "^red;"
    widget.setText("essenceCost", string.format("%s%s / %s", directive, playerModule, price))
  else
    widget.setText("essenceCost", string.format("%s / --", playerModule))
  end

  widget.setButtonEnabled("btnUpgrade", enableButton)
end

function itemSelected()
  local listItem = widget.getListSelected(self.itemList)
  self.selectedItem = listItem

  if listItem then
    local itemData = widget.getData(string.format("%s.%s", self.itemList, listItem))
    local weaponItem = self.upgradeableWeaponItems[itemData.index]
    showWeapon(weaponItem, itemData.price)
  end
end


function doUpgrade()
  if self.selectedItem then
    local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))  
    local upgradeItem = self.upgradeableWeaponItems[selectedData.index]

    if upgradeItem then
      local consumedItem = player.consumeItem(upgradeItem, false, true)
      if consumedItem then
        --local consumedCurrency = player.consumeItem("manipulatormodule", false, selectedData.price)
        local consumedCurrency = player.consumeItem({name = "manipulatormodule", count = selectedData.price}, false, true)
        local upgradedItem = copy(consumedItem)
        if consumedCurrency then
        
          local itemConfig = root.itemConfig(upgradedItem)  
		  upgradedItem.parameters.level = (itemConfig.parameters.level or itemConfig.config.level or 1) + 1
		  upgradedItem.parameters.critChance = (itemConfig.parameters.critChance or itemConfig.config.critChance or 1) + 1  -- increase Crit Chance
		  upgradedItem.parameters.critBonus = (itemConfig.parameters.critBonus or itemConfig.config.critBonus or 1) + 1     -- increase Crit Damage    


	 -- set Rarity
	 if upgradedItem.parameters.level ==4 then
	   upgradedItem.parameters.rarity = "uncommon"
	 elseif upgradedItem.parameters.level == 5 then
	   upgradedItem.parameters.rarity = "rare"
	 elseif upgradedItem.parameters.level == 6 then
	   upgradedItem.parameters.rarity = "legendary"
	 elseif upgradedItem.parameters.level >= 7 then
	   upgradedItem.parameters.rarity = "essential"	   
	 end
	 
			  
          upgradedItem.parameters.primaryAbility = {}   

		  if (itemConfig.config.primaryAbility) then	 
			  
		    -- beams and miners
			if (itemConfig.config.primaryAbility.beamLength) then
			  upgradedItem.parameters.primaryAbility.beamLength= itemConfig.config.primaryAbility.beamLength + ( upgradedItem.parameters.level * 3.14 )
			  upgradedItem.parameters.primaryAbility.energyUsage= itemConfig.config.primaryAbility.energyUsage + ( upgradedItem.parameters.level /10 )
			end
		  -- does the item have primaryAbility and a baseDps if so, we increase the DPS slightly
			if (itemConfig.config.primaryAbility.baseDps) and not (itemConfig.config.primaryAbility.baseDps >=20) then    
			    local baseDpsBase = itemConfig.config.primaryAbility.baseDps
			    local baseDpsMod = (upgradedItem.parameters.level/25)
			    local baseDpsFinal = baseDpsBase * (1 + baseDpsMod )
			    upgradedItem.parameters.primaryAbility.baseDps = baseDpsFinal 
			end			
		  end
	  
	  sb.logInfo("Upgrading weapon : ")	  
          sb.logInfo(sb.printJson(upgradedItem,1)) -- list all current bonuses being applied to the weapon for debug 
          
          if (upgradedItem.parameters.level) < 4 then
            upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters)
          elseif (upgradedItem.parameters.level) == 4 then
            upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
          elseif (upgradedItem.parameters.level) == 5 then
            upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)            
          elseif (upgradedItem.parameters.level) == 6 then
            upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters3)
          elseif (upgradedItem.parameters.level) == 7 then
            upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters3)            
          end
                   
        end
        player.giveItem(upgradedItem)
      end
    end
    populateItemList(true)
  end
end
