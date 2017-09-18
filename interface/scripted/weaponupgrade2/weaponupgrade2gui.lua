require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.itemList = "itemScrollArea.itemList"

  self.upgradeLevel = 8

  self.upgradeableWeaponItems = {}
  self.selectedItem = nil
  populateItemList()
end

function update(dt)
  populateItemList()
end

function upgradeCost(itemConfig)
  if itemConfig == nil then return 0 end

  local prevValue = root.evalFunction("weaponEssenceValue", itemConfig.parameters.level or itemConfig.config.level or 1)
  local newValue = (root.evalFunction("weaponEssenceValue", self.upgradeLevel) * (itemConfig.parameters.level or itemConfig.config.level or 1)/3) + 200

  return math.floor(newValue - prevValue)
end


function populateItemList(forceRepop)
  local upgradeableWeaponItems = player.itemsWithTag("upgradeableWeapon")
  for i = 1, #upgradeableWeaponItems do
    upgradeableWeaponItems[i].count = 1
  end

  widget.setVisible("emptyLabel", #upgradeableWeaponItems == 0)

  local playerEssence = player.currency("essence")

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

        widget.setVisible(string.format("%s.unavailableoverlay", listItem), price > playerEssence)
      end
    end

    self.selectedItem = nil
    showWeapon(nil)
  end
end

function showWeapon(item, price)
  local playerEssence = player.currency("essence")
  local enableButton = false

  if item then
    enableButton = playerEssence >= price
    local directive = enableButton and "^green;" or "^red;"
    widget.setText("essenceCost", string.format("%s%s / %s", directive, playerEssence, price))
  else
    widget.setText("essenceCost", string.format("%s / --", playerEssence))
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

function isArmor()
  if (upgradedItem.parameters.category == "legarmor") or (upgradedItem.parameters.category == "chestarmor") or (upgradedItem.parameters.category == "headarmor") then
     isArmorSet = 1
  return isArmorSet
  end
end

function doUpgrade()
  if self.selectedItem then
    local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))
    local upgradeItem = self.upgradeableWeaponItems[selectedData.index]

    if upgradeItem then
      local consumedItem = player.consumeItem(upgradeItem, false, true)
      if consumedItem then
        local consumedCurrency = player.consumeCurrency("essence", selectedData.price)
        local upgradedItem = copy(consumedItem)
        if consumedCurrency then
        
          local itemConfig = root.itemConfig(upgradedItem)  
                  self.baseValueMod = itemConfig.config.level or 1 -- store the original level in case we need it for calculations
		  upgradedItem.parameters.level = (itemConfig.parameters.level or itemConfig.config.level or 1) + 1
		  if (itemConfig.parameters.baseDps) or (itemConfig.config.baseDps) then
		    upgradedItem.parameters.baseDps = (itemConfig.parameters.baseDps or itemConfig.config.baseDps or 1) * (1 + (upgradedItem.parameters.level/20) )  -- increase DPS a bit
		  end
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
	 

	 
	                -- is it a fishing rod?
	 		if (itemConfig.config.category == "fishingRod") then
	 		   if itemConfig.parameters.reelParameters then
	 		        upgradedItem.parameters.reelParameters.reelOutLength = (itemConfig.parameters.reelParameters.reelOutLength or 1) +10
				upgradedItem.parameters.reelParameters.reelSpeed = (itemConfig.parameters.reelParameters.reelSpeed or 1) +2
				upgradedItem.parameters.reelParameters.lineBreakTime = (itemConfig.parameters.reelParameters.lineBreakTime or 1) +0.1
	 		   end		    
			 end	
	 		if (itemConfig.config.category == "Tool") or (itemConfig.config.category == "tool") then
	 		  -- parasol
	 		   if upgradedItem.parameters.fallingParameters then
	 		     upgradedItem.parameters.fallingParameters.airForce = (itemConfig.parameters.airForce or itemConfig.config.airForce or 1) * 1.15 
	 		     upgradedItem.parameters.fallingParameters.runSpeed = (itemConfig.parameters.runSpeed or itemConfig.config.runSpeed or 1) * 1.15 
	 		     upgradedItem.parameters.fallingParameters.walkSpeed = (itemConfig.parameters.walkSpeed or itemConfig.config.walkSpeed or 1) * 1.15 
	 		   end
	 		   if upgradedItem.parameters.maxFallSpeed then
	 		     upgradedItem.parameters.maxFallSpeed = (itemConfig.parameters.maxFallSpeed or itemConfig.config.maxFallSpeed or 1) - 4 
	 		   end	 		
	 		
	 		    -- hoe, chainsaw, etc
			    if upgradedItem.parameters.fireTime then
			      upgradedItem.parameters.fireTime = (itemConfig.parameters.fireTime or itemConfig.config.fireTime or 1) * 1.15 
			    end
			    if upgradedItem.parameters.blockRadius then
			      upgradedItem.parameters.blockRadius = (itemConfig.parameters.blockRadius or itemConfig.config.blockRadius or 1) + 1
			    end	
			    if upgradedItem.parameters.altBlockRadius then
			      upgradedItem.parameters.altBlockRadius = (itemConfig.parameters.altBlockRadius or itemConfig.config.altBlockRadius or 1) + 1
			    end			    
			 end
			  
                  -- is it a shield?
			  if (itemConfig.config.category == "shield") then
			    upgradedItem.parameters.shieldBash = (itemConfig.parameters.shieldBash or itemConfig.config.shieldBash or 1) + 0.5 + self.baseValueMod  
		            upgradedItem.parameters.shieldBashPush = (itemConfig.parameters.shieldBashPush or itemConfig.config.shieldBashPush or 1) + 0.5  
			    if upgradedItem.parameters.cooldownTime then
			      upgradedItem.parameters.cooldownTime = (itemConfig.parameters.cooldownTime or itemConfig.config.cooldownTime or 1) * 0.95 
			    end
			    if upgradedItem.parameters.perfectBlockTime then
			      upgradedItem.parameters.perfectBlockTime = (itemConfig.parameters.perfectBlockTime or itemConfig.config.perfectBlockTime or 1) * 1.05
			    end
			    if upgradedItem.parameters.baseShieldHealth then
			      upgradedItem.parameters.baseShieldHealth = (itemConfig.parameters.baseShieldHealth or itemConfig.config.baseShieldHealth or 1) * 1.15
			    end
			  end
          upgradedItem.parameters.primaryAbility = {}   
          
                  -- is it a staff or wand?
			  if (itemConfig.config.category == "staff") or (itemConfig.config.category == "wand") then
			    upgradedItem.parameters.primaryAbility = {} 
			    if (itemConfig.config.baseDamageFactor) then
			      upgradedItem.parameters.baseDamageFactor = (itemConfig.parameters.baseDamageFactor or itemConfig.config.baseDamageFactor or 1) * 1.15 
			    end	    
			  end 
			  
                  -- magnorbs
                  if (upgradedItem.parameters.orbitRate) then
                    upgradedItem.parameters.shieldKnockback = (itemConfig.parameters.shieldKnockback or itemConfig.config.shieldKnockback or 1) + 1 
                    upgradedItem.parameters.shieldEnergyCost = (itemConfig.parameters.shieldEnergyCost or itemConfig.config.shieldEnergyCost or 1) + 1 
                    upgradedItem.parameters.shieldHealth = (itemConfig.parameters.shieldHealth or itemConfig.config.shieldHealth or 1) + 1 
                  end  
                  
                  -- boomerangs and other projectileParameters based things (magnorbs here too , chakrams)
		  if (upgradedItem.parameters.projectileParameters) then   
		    upgradedItem.parameters.projectileParameters = { 
		        power = itemConfig.config.primaryAbility.power + (upgradedItem.parameters.level/7),
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
		  -- does the item have primaryAbility and a Fire Time? if so, we reduce fire time slightly as long as the weapon isnt already fast firing 
			
			if (itemConfig.config.primaryAbility.fireTime) and not (itemConfig.config.primaryAbility.fireTime <= 0.1) then
			  if (itemConfig.config.category == "axe") or (itemConfig.config.category == "hammer") or (itemConfig.config.category == "katana") or (itemConfig.config.category == "mace") or (itemConfig.config.category == "greataxe") or (itemConfig.config.category == "scythe") then
			    upgradedItem.parameters.primaryAbility.fireTime = upgradedItem.parameters.primaryAbility.fireTime
			  else
			    local fireTimeBase = itemConfig.config.primaryAbility.fireTime
			    local fireTimeMod = ( upgradedItem.parameters.level/10 * 0.5)
			    local fireTimeFinal = fireTimeBase * fireTimeMod 
			    local fireTimeFinal2 = fireTimeBase - fireTimeFinal
			    upgradedItem.parameters.primaryAbility.fireTime = fireTimeFinal2 
			  end
			end

		  -- does the item have primaryAbility and a baseDps if so, we increase the DPS slightly
			if (itemConfig.config.primaryAbility.baseDps) and not (itemConfig.config.primaryAbility.baseDps >=20) then    
			    local baseDpsBase = itemConfig.config.primaryAbility.baseDps
			    local baseDpsMod = (upgradedItem.parameters.level/20)
			    local baseDpsFinal = baseDpsBase * (1 + baseDpsMod )
			    upgradedItem.parameters.primaryAbility.baseDps = baseDpsFinal 
			end	
		  -- Can it STUN?	
                  if (itemConfig.config.category == "hammer") or (itemConfig.config.category == "mace") or (itemConfig.config.category == "greataxe") or (itemConfig.config.category == "quarterstaff") then
 		    upgradedItem.parameters.stunChance = (itemConfig.parameters.stunChance or itemConfig.config.stunChance or 1) + 0.5 + self.baseValueMod                    
                  end     
                  
		  end
	  
	  sb.logInfo("Upgrading weapon : ")	  
          sb.logInfo(sb.printJson(upgradedItem,1)) -- list all current bonuses being applied to the weapon for debug 
          
          if (itemConfig.config.upgradeParameters)  and (upgradedItem.parameters.level) > 3 then
            upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters)
          end
          if (itemConfig.config.upgradeParameters2) and (upgradedItem.parameters.level) > 5 then
            upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
          end
          
        end
        player.giveItem(upgradedItem)
      end
    end
    populateItemList(true)
  end
end
