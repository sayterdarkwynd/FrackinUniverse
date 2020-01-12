require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/researchGenerators.lua"

function init()
	self.itemList = "itemScrollArea.itemList"
	self.upgradeLevel = 6
	self.upgradeableWeaponItems = {}
	self.selectedItem = nil
	populateItemList()
end

function update(dt)
	populateItemList()
	
end

function upgradeCost(itemConfig)
	if itemConfig == nil then return 0 end
	local newValue = (itemConfig.parameters.level or itemConfig.config.level) or 1--cost is current level in upgrade modules
	return math.floor(newValue)
end

function populateItemList(forceRepop)
	local upgradeableWeaponItems = player.itemsWithTag("upgradeableWeapon")
	for i = 1, #upgradeableWeaponItems do
		upgradeableWeaponItems[i].count = 1
	end
	
	widget.setVisible("emptyLabel", #upgradeableWeaponItems == 0)
	
	local playerEssence = player.hasCountOfItem("upgrademodule", true)
	
	if forceRepop or not compare(upgradeableWeaponItems, self.upgradeableWeaponItems) then
		self.upgradeableWeaponItems = upgradeableWeaponItems
		widget.clearListItems(self.itemList)
		widget.setButtonEnabled("btnUpgrade", false)
	
		for i, item in pairs(self.upgradeableWeaponItems) do
			local config = root.itemConfig(item)
			
			if (config.parameters.level or config.config.level or 1) < self.upgradeLevel then
				local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
				local name = config.parameters.shortdescription or config.config.shortdescription
				
				widget.setText(string.format("%s.itemName", listItem), name)
				widget.setItemSlotItem(string.format("%s.itemIcon", listItem), item)
				
				local price = upgradeCost(config)
				widget.setData(listItem, { index = i, price = price })
			
				widget.setVisible(string.format("%s.unavailableoverlay", listItem), price > playerEssence)
			end
		end
		
		self.selectedItem = nil
		showWeapon(nil)
	end
end

function showWeapon(item, price)
	local playerEssence = player.hasCountOfItem("upgrademodule", true)
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
				local consumedCurrency = player.consumeItem({name = "upgrademodule", count = selectedData.price}, false, true) 
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
		populateItemList(true)
	end
end