require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/furesearchGenerators.lua"

local cosmeticList={legwear=true,chestwear=true,headwear=true,backwear=true}
local armorList={legarmour=true,chestarmour=true,headarmour=true,enviroProtectionPack=true}
local cosmeticSlotList={"headCosmetic", "chestCosmetic", "legsCosmetic", "backCosmetic"}
local armorSlotList={"head", "chest", "legs", "back"}

function init()
	self.itemList = "itemScrollArea.itemList"
	self.isUpgradeKit = true

	local upgradeAnvil = world.objectQuery(world.entityPosition(player.id()), 5, { name = "weaponupgradeanvil2" })
	if upgradeAnvil and #upgradeAnvil > 0 then
		self.isUpgradeKit = false
	end

	if self.isUpgradeKit then
		local upgradeAnvil = world.objectQuery(world.entityPosition(player.id()), 5, { name = "extraweaponupgradeanvil" })
		if upgradeAnvil and #upgradeAnvil > 0 then
			self.isUpgradeKit = false
		end
	end

	self.upgradeLevel = 8
	self.maxEssenceValue=root.evalFunction("weaponEssenceValue", self.upgradeLevel)
	self.upgradeableWeaponItems = {}
	self.selectedItem = nil
	populateItemList()
	
	widget.setText("warningLabel","")
end

function update(dt)
	populateItemList()
	itemSelected()
end

function upgradeCost(itemConfig,fullUpgrade)
	if (not itemConfig) or self.isUpgradeKit then return 0 end
	local iLvl=itemConfig.parameters.level or itemConfig.config.level or 1
	local currentValue=0

	if fullUpgrade then
	--61841 from 1 to 8
		while iLvl<self.upgradeLevel do
			currentValue=currentValue+costMath(iLvl)
			iLvl=iLvl+1
		end
	else
		currentValue=costMath(iLvl)
	end

	return math.floor(currentValue)
end

function costMath(iLvl,targetILvl)
	local prevValue = root.evalFunction("weaponEssenceValue", iLvl)
	local newValue = (self.maxEssenceValue * iLvl / 3) + 200
	return math.floor(newValue-prevValue)
end

function populateItemList(forceRepop)
	local upgradeableWeaponItems = player.itemsWithTag("upgradeableWeapon")
	local buffer = {}
	
	for i = 1, #upgradeableWeaponItems do		
		upgradeableWeaponItems[i].count = 1
		table.insert(buffer,upgradeableWeaponItems[i])
	end
	
	upgradeableWeaponItems=buffer
	buffer={}

	widget.setVisible("emptyLabel", #upgradeableWeaponItems == 0)

	local playerEssence = player.currency("essence")

	if forceRepop or not compare(upgradeableWeaponItems, self.upgradeableWeaponItems) then
		self.upgradeableWeaponItems = upgradeableWeaponItems
		widget.clearListItems(self.itemList)
		widget.setButtonEnabled("btnUpgrade", false)
		widget.setButtonEnabled("btnUpgradeMax", false)

		for i, item in pairs(self.upgradeableWeaponItems) do
			local config = root.itemConfig(item)

			if (config.parameters.level or config.config.level or 1) < self.upgradeLevel then
				local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
				local name = config.parameters.shortdescription or config.config.shortdescription

				widget.setText(string.format("%s.itemName", listItem), name)
				widget.setItemSlotItem(string.format("%s.itemIcon", listItem), item)

				local price = upgradeCost(config)
				widget.setData(listItem, { index = i })

				widget.setVisible(string.format("%s.unavailableoverlay", listItem), price > playerEssence)
			end
		end

		self.selectedItem = nil
		showWeapon(nil)
	end
end

function showWeapon(item, price, priceMax)
	local playerEssence = player.currency("essence")
	local enableButton = false
	local enableButtonMax = false
	local isWorn = item and checkWorn(item)

	widget.setText("warningLabel",isWorn and "Error: "..isWorn or "")
	
	if not self.isUpgradeKit then
		if item then
			
			enableButton = price and (playerEssence >= price) and not isWorn
			enableButtonMax = priceMax and (playerEssence >= priceMax) and not isWorn
			local directive = enableButton and "^green;" or "^red;"
			local directive2 = enableButtonMax and "^green;" or "^red;"
			widget.setText("essenceCost", string.format("%s / %s%s^reset; (%s%s^reset;)", playerEssence,directive, price or "--",directive2, priceMax or "--"))
		else
			widget.setText("essenceCost", string.format("%s / -- (--)", playerEssence))
		end
	else
		local hasKit=(player.hasCountOfItem({name = "cuddlehorse", count = 1}) or 0) > 0
		widget.setText("essenceCost",hasKit and "^green;FREE FROM UPGRADE KIT" or "^red;MISSING UPGRADE KIT")
		enableButton=hasKit and not isWorn
	end
	widget.setButtonEnabled("btnUpgradeMax",enableButtonMax)
	widget.setButtonEnabled("btnUpgrade", enableButton)
end

function getSelectedItem()
	if not self.selectedItem then return end
	return self.upgradeableWeaponItems[widget.getData(string.format("%s.%s", self.itemList, self.selectedItem)).index]
end

function itemSelected()
	self.selectedItem = widget.getListSelected(self.itemList)

	if self.selectedItem then
		local weaponItem = getSelectedItem()
		showWeapon(weaponItem, upgradeCost(root.itemConfig(weaponItem)), upgradeCost(root.itemConfig(weaponItem),true))
	end
end

function doUpgradeMax()
	if self.selectedItem and self.isUpgradeKit then return end
	
	local isWorn=checkWorn(getSelectedItem())
	if isWorn then
		widget.setText("warningLabel",isWorn and "Error: "..isWorn or "")
		widget.setButtonEnabled("btnUpgrade", false)
		return
	end
	
	upgrade(true)
end

function doUpgrade()
	if self.selectedItem then
		if self.isUpgradeKit and not player.consumeItem({name = "cuddlehorse", count = 1}, true) then
			widget.setButtonEnabled("btnUpgrade", false)
			return
		end
		
		local isWorn=checkWorn(getSelectedItem())
		if isWorn then
			widget.setText("warningLabel",isWorn and "Error: "..isWorn or "")
			widget.setButtonEnabled("btnUpgrade", false)
			widget.setButtonEnabled("btnUpgradeMax", false)
			return
		end
		
		upgrade(false)
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

function upgrade(fullUpgrade)
	local upgradeItem=getSelectedItem()

	if upgradeItem then
		if checkWorn(upgradeItem) then
			return
		end
		local consumedItem = player.consumeItem(upgradeItem, false, true)
		if consumedItem then
			local consumedCurrency = player.consumeCurrency("essence", (fullUpgrade and upgradeCost(root.itemConfig(upgradeItem),true) or upgradeCost(root.itemConfig(upgradeItem))))
			local upgradedItem = copy(consumedItem)
			if consumedCurrency then

				local itemConfig = root.itemConfig(upgradedItem)
				self.baseValueMod = itemConfig.config.level or 1 -- store the original level in case we need it for calculations
				upgradedItem.parameters.level = (itemConfig.parameters.level or itemConfig.config.level or 1) + 1
				if fullUpgrade then
					upgradedItem.parameters.level=math.max(upgradedItem.parameters.level,self.upgradeLevel)
				end
				if (itemConfig.parameters.baseDps) or (itemConfig.config.baseDps) then
					upgradedItem.parameters.baseDps = (itemConfig.parameters.baseDps or itemConfig.config.baseDps or 1) * (1 + (upgradedItem.parameters.level/80) )  -- increase DPS a bit
				end

				upgradedItem.parameters.critChance = (itemConfig.parameters.critChance or itemConfig.config.critChance or 1) + 0.15  -- increase Crit Chance
				upgradedItem.parameters.critBonus = (itemConfig.parameters.critBonus or itemConfig.config.critBonus or 1) + 0.5     -- increase Crit Damage

				-- is it a rapier?
				if (itemConfig.config.category == "rapier") or (itemConfig.config.category == "Rapier") or (itemConfig.config.category == "katana") or (itemConfig.config.category == "mace") then
				  upgradedItem.parameters.critChance = (itemConfig.parameters.critChance or itemConfig.config.critChance or 1) + 0.10
				  upgradedItem.parameters.critBonus = (itemConfig.parameters.critBonus or itemConfig.config.critBonus or 1) + 0.5     -- increase Crit Damage
				end

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

					--[[removing all fire rate modifiers due to the annoying bugs and scaling issues
					-- hoe, chainsaw, etc
					if upgradedItem.parameters.fireTime then
						if not (itemConfig.config.category == "Gun Staff") and not (itemConfig.config.category == "sggunstaff") then --exclude Shellguard gunblades from this bit to not break their rotation
						  upgradedItem.parameters.fireTime = (itemConfig.parameters.fireTime or itemConfig.config.fireTime or 1) * 1.15
						end
					end]]

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
						upgradedItem.parameters.cooldownTime = (itemConfig.parameters.cooldownTime or itemConfig.config.cooldownTime or 1) * 0.98
					end

					if upgradedItem.parameters.perfectBlockTime then
						upgradedItem.parameters.perfectBlockTime = (itemConfig.parameters.perfectBlockTime or itemConfig.config.perfectBlockTime or 1) * 1.05
					end
					if upgradedItem.parameters.shieldEnergyBonus then
						upgradedItem.parameters.shieldEnergyBonus = (itemConfig.parameters.shieldEnergyBonus or itemConfig.config.shieldEnergyBonus or 1) * 1.05
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
					if not (itemConfig.config.category == "Gun Staff") and not (itemConfig.config.category == "sggunstaff") then --exclude Shellguard gunblades from this bit to not break their rotation
						-- bows
						if (itemConfig.config.category == "bow") then
							if (itemConfig.config.primaryAbility.drawTime) then
								upgradedItem.parameters.primaryAbility.drawTime = (itemConfig.config.primaryAbility.drawTime or 0) - 0.05
							end
							if (itemConfig.config.primaryAbility.powerProjectileTime) then
								upgradedItem.parameters.primaryAbility.powerProjectileTime = (itemConfig.config.primaryAbility.powerProjectileTime or 0) + 0.05
							end
							if (itemConfig.config.primaryAbility.energyPerShot) then
								upgradedItem.parameters.primaryAbility.energyPerShot = (itemConfig.config.primaryAbility.energyPerShot or 0.15) - 2
							end
							if (itemConfig.config.primaryAbility.holdEnergyUsage) then
								upgradedItem.parameters.primaryAbility.holdEnergyUsage = (itemConfig.config.primaryAbility.holdEnergyUsage or 1) - 0.5
							end
							if (itemConfig.config.primaryAbility.airborneBonus) then
								upgradedItem.parameters.primaryAbility.airborneBonus = (itemConfig.config.primaryAbility.airborneBonus or 0) + 0.02
							end
						end
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


						--[[removing all fire rate modifiers due to the annoying bugs and scaling issues
						-- we reduce fire time slightly as long as the weapon isnt already too fast firing.
						if (itemConfig.config.primaryAbility.fireTime) then
						  local fireTimeBase = itemConfig.config.primaryAbility.fireTime
						  local fireTimeMod = ( upgradedItem.parameters.level/20 * 0.25)
						  local fireTimeFinal = fireTimeBase * fireTimeMod
						  local fireTimeFinal2 = fireTimeBase - fireTimeFinal
							sb.logInfo("firetimefinal2 %s",fireTimeFinal2)
						  if (itemConfig.config.category == "Rapier") or (itemConfig.config.category == "rapier") or (itemConfig.config.category == "axe") or (itemConfig.config.category == "hammer") or (itemConfig.config.category == "katana") or (itemConfig.config.category == "mace") or (itemConfig.config.category == "greataxe") or (itemConfig.config.category == "scythe") or (itemConfig.config.primaryAbility.fireTime <= 0.25) then
							upgradedItem.parameters.primaryAbility.fireTime = fireTimeBase
						  else
							upgradedItem.parameters.primaryAbility.fireTime = fireTimeFinal2
						  end

						end]]

						-- does the item have primaryAbility and a baseDps if so, we increase the DPS slightly
						if (itemConfig.config.primaryAbility.baseDps) and not (itemConfig.config.primaryAbility.baseDps >=20) then
							local baseDpsBase = itemConfig.config.primaryAbility.baseDps
							local baseDpsMod = (upgradedItem.parameters.level/79)
							local baseDpsFinal = baseDpsBase * (1 + baseDpsMod )
							upgradedItem.parameters.primaryAbility.baseDps = baseDpsFinal
						end

						-- Can it STUN?
						if (itemConfig.config.category == "hammer") or (itemConfig.config.category == "mace") or (itemConfig.config.category == "greataxe") or (itemConfig.config.category == "quarterstaff") then
							upgradedItem.parameters.stunChance = (itemConfig.parameters.stunChance or itemConfig.config.stunChance or 1) + 0.5 + self.baseValueMod
						end
					else
					 --gunblade upgrade data here
					end
				end

				sb.logInfo("Pre-Upgrade Stats : ")
				sb.logInfo(sb.printJson(upgradedItem,1)) -- list all current bonuses being applied to the weapon for debug

				if (itemConfig.config.upgradeParameters) and (upgradedItem.parameters.level) > 4 then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters)
				end

				if (itemConfig.config.upgradeParameters2) and (upgradedItem.parameters.level) > 5 then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters2)
				end
				if (itemConfig.config.upgradeParameters3) and (upgradedItem.parameters.level) > 6 then
					upgradedItem.parameters = util.mergeTable(upgradedItem.parameters, itemConfig.config.upgradeParameters3)
				end
			end

			-- check if player gets Research randomly
			checkResearchBonus()
			player.giveItem(upgradedItem)
			sb.logInfo("Upgraded Stats: ")
			sb.logInfo(sb.printJson(upgradedItem,1)) -- list all current bonuses being applied to the weapon for debug

		end
	end

	if self.isUpgradeKit then
		pane.dismiss()
	else
		populateItemList(true)
	end
end
