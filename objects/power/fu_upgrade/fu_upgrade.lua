require "/scripts/kheAA/transferUtil.lua"
local deltaTime=0
function init()
	transferUtil.init()
	-- these are items wich will be used for upgrade
	upgradeItemsList = {
		["upgrademodule"] = true
	}
	-- these are types of items, which can be improved
	upgradebleItemsList = {
		["sword"] = true,
		["gun"] = true,
		["shield"] = true,
		["headarmor"] = true,
		["chestarmor"] = true,
		["legarmor"] = true,
		["backarmor"] = true,
		["backwear"] = true,
		["enviroProtectionPack"] = true
	}
end


function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end

	local itemForUpgrade = world.containerItemAt(entity.id(), 0)
  if isn_hasRequiredPower() == false then
    object.setLightColor({0, 0, 0, 0})
    return
  end
  object.setLightColor(config.getParameter("lightColor", {100, 176, 191}))	
	if itemForUpgrade ~= nil and upgradebleItemsList[root.itemType(itemForUpgrade.name)] and itemForUpgrade.count ~= nil and itemForUpgrade.count == 1 then
		local isUpgraded = false -- flag, upgrade is not possible or while not done
		sb.logInfo("Trying to upgrade. Name is '" .. itemForUpgrade.name .. "'. root.itemType returns '" .. root.itemType(itemForUpgrade.name) .. "'.")

		-- Begin SHIELD Item Upgrade
		if root.itemType(itemForUpgrade.name) == "shield" then
			--sb.logInfo("==> Shield is : %s", itemForUpgrade)
			local shieldHLTH = world.containerItemAt(entity.id(), 8)
			if isApproved(shieldHLTH) then -- upgrade Shield Health
				world.containerTakeAt(entity.id(), 8) -- clear slot
				if itemForUpgrade.parameters.health ~= nil then 
					itemForUpgrade.parameters.health = itemForUpgrade.parameters.health + shieldHLTH.count * 5
				else
					itemForUpgrade.parameters.health = shieldHLTH.count * 5
				end
				isUpgraded = true
			end
			
			local shieldHLTHRGN = world.containerItemAt(entity.id(), 9)
			if isApproved(shieldHLTHRGN) then -- upgrade Shield Health Regen Ratio
				world.containerTakeAt(entity.id(), 9) -- clear slot
				if itemForUpgrade.parameters.healthRegen ~= nil then
					itemForUpgrade.parameters.healthRegen = itemForUpgrade.parameters.healthRegen + shieldHLTHRGN.count * 0.05
				else
					itemForUpgrade.parameters.healthRegen = shieldHLTHRGN.count * 0.05
				end
				isUpgraded = true
			end
		end
		-- End SHIELD Item Upgrade

		-- Begin ARMOR Item Upgrade
		if root.itemType(itemForUpgrade.name) == "headarmor" or root.itemType(itemForUpgrade.name) == "chestarmor" or root.itemType(itemForUpgrade.name) == "legsarmor" or root.itemType(itemForUpgrade.name) == "backarmor" then
			if itemForUpgrade.parameters.statusEffects == nil then
				sb.logInfo("==> Armor is : %s", itemForUpgrade)
				local itemConf = root.itemConfig(itemForUpgrade)
				-- sb.logInfo("==> ItemConf is : %s", itemConf)
				if itemConf.config == nil and itemConf.statusEffects ~= nil then  -- this for Starbound Stable version 
					itemForUpgrade.parameters.statusEffects = itemConf.statusEffects
				elseif itemConf.config.statusEffects ~= nil then -- this for Strbound Unstable nightly version
					itemForUpgrade.parameters.statusEffects = itemConf.config.statusEffects
					-- sb.logInfo("==> statusEffects is : %s", itemForUpgrade.parameters.statusEffects)
				else
					itemForUpgrade.parameters.statusEffects = {}
				end
			end
			
			local armorDMGM = world.containerItemAt(entity.id(), 1)
			if isApproved(armorDMGM) then --upgade Armor power Multiplier
				world.containerTakeAt(entity.id(), 1) -- clear slot
				itemForUpgrade.parameters.statusEffects = armorStatUpgrade(itemForUpgrade.parameters.statusEffects, "powerMultiplier", armorDMGM)
				isUpgraded = true
			end

			local armorPRT = world.containerItemAt(entity.id(), 2)
			if isApproved(armorPRT) then --upgade Armor Protection
				world.containerTakeAt(entity.id(), 2) -- clear slot
				itemForUpgrade.parameters.statusEffects = armorStatUpgrade(itemForUpgrade.parameters.statusEffects, "protection", armorPRT)
				isUpgraded = true
			end

			local armorMAXE = world.containerItemAt(entity.id(), 3)
			if isApproved(armorMAXE) then --upgade Armor maximum Energy
				world.containerTakeAt(entity.id(), 3) -- clear slot
				itemForUpgrade.parameters.statusEffects = armorStatUpgrade(itemForUpgrade.parameters.statusEffects, "maxEnergy", armorMAXE)
				isUpgraded = true
			end

			local armorMAXH = world.containerItemAt(entity.id(), 4)
			if isApproved(armorMAXH) then --upgade Armor maximum Health
				world.containerTakeAt(entity.id(), 4) -- clear slot
				itemForUpgrade.parameters.statusEffects = armorStatUpgrade(itemForUpgrade.parameters.statusEffects, "maxHealth", armorMAXH)
				isUpgraded = true
			end
		end
		-- End ARMOR Item Upgrade

		-- Begin WEAPON Item Upgrade
		if root.itemType(itemForUpgrade.name) == "sword" or root.itemType(itemForUpgrade.name) == "gun" then
			local weaponDMG = world.containerItemAt(entity.id(), 5)
			if isApproved(weaponDMG) then -- upgrade Weapon Damage
				world.containerTakeAt(entity.id(), 5) -- clear slot

				-- For Guns
				if root.itemType(itemForUpgrade.name) == "gun" and itemForUpgrade.parameters.projectile ~= nil then
					if itemForUpgrade.parameters.levelScale == nil then
						itemForUpgrade.parameters.levelScale = root.evalFunction("gunDamageLevelMultiplier", itemForUpgrade.parameters.level)
					end
					itemForUpgrade.parameters.projectile.power = (itemForUpgrade.parameters.levelScale * itemForUpgrade.parameters.projectile.power + weaponDMG.count) / itemForUpgrade.parameters.levelScale
				end

				-- For Swords and etc
				if root.itemType(itemForUpgrade.name) == "sword" and itemForUpgrade.parameters.primaryStances.projectile ~= nil then
					if itemForUpgrade.parameters.levelScale == nil then
						itemForUpgrade.parameters.levelScale = root.evalFunction("swordDamageLevelMultiplier", itemForUpgrade.parameters.level)
					end
					itemForUpgrade.parameters.primaryStances.projectile.power = (itemForUpgrade.parameters.levelScale * itemForUpgrade.parameters.primaryStances.projectile.power + weaponDMG.count) / itemForUpgrade.parameters.levelScale
				end

				isUpgraded = true
			end

			local weaponSPD = world.containerItemAt(entity.id(), 6)
			if isApproved(weaponSPD) and itemForUpgrade.parameters.fireTime ~= nil and itemForUpgrade.parameters.fireTime >= 0.06 then -- upgrade Weapon Fire Speed (for guns, swords and etc)
				local weaponROF = 1 / itemForUpgrade.parameters.fireTime
				world.containerTakeAt(entity.id(), 6) -- clear slot
				if weaponROF + weaponSPD.count * 0.02 <= 20 then
					itemForUpgrade.parameters.fireTime = 1 / (weaponROF + weaponSPD.count * 0.02)
				else
					weaponSPD.count = weaponSPD.count - math.ceil((weaponROF + weaponSPD.count * 0.02 - 20) / 0.02)
					itemForUpgrade.parameters.fireTime = 0.1
					world.containerPutItemsAt(entity.id(), weaponSPD, 6) -- return not used items
				end
				isUpgraded = true 
			end
			
			local weaponENRG = world.containerItemAt(entity.id(), 7)
			if root.itemType(itemForUpgrade.name) == "gun" and isApproved(weaponENRG) then -- upgrade Weapon Energy cost per shot (for guns only)
				if itemForUpgrade.parameters.classMultiplier == nil then
					itemForUpgrade.parameters.classMultiplier = 1
				end

				local energyM = itemForUpgrade.parameters.projectile.power * itemForUpgrade.parameters.levelScale * root.evalFunction("gunLevelEnergyCostPerDamage", itemForUpgrade.parameters.level)
				world.containerTakeAt(entity.id(), 7) -- clear slot
				if energyM * itemForUpgrade.parameters.classMultiplier - weaponENRG.count > 0 then
					itemForUpgrade.parameters.classMultiplier = (energyM * itemForUpgrade.parameters.classMultiplier - weaponENRG.count) / energyM  -- i'm not sure, but it's working
				else
					weaponENRG.count = weaponENRG.count - math.floor(energyM * itemForUpgrade.parameters.classMultiplier)
					world.containerPutItemsAt(entity.id(), weaponENRG, 7) -- return not used items 
					itemForUpgrade.parameters.classMultiplier = 0.9 / energyM  -- i'm not sure, but it's working
				end
				isUpgraded = true
			end
		end
		-- End WEAPON Item Upgrade

		if isUpgraded then
			world.containerTakeAt(entity.id(), 0) -- clear Item slot
			-- sb.logInfo("==> New Item is : %s", itemForUpgrade)
			world.containerPutItemsAt(entity.id(), itemForUpgrade, 0)
		end
	end
end

function isApproved(inputItem) 
	if inputItem ~= nil and inputItem.count ~= nil and inputItem.count > 0 and type(inputItem.name) == "string" and upgradeItemsList[inputItem.name] then
		return true
	else
		return false
	end
end

function armorStatUpgrade(statusList, statusName, statUpgradeItem)
	local statUpgraded = false
	local statUpgradeAmount = nil

	if statusName == "powerMultiplier" then
		statUpgradeAmount = statUpgradeItem.count * 0.01
	elseif statusName == "protection" then
		statUpgradeAmount = statUpgradeItem.count + math.floor(statUpgradeItem.count / 10) * 2
	elseif statusName == "maxEnergy" then
		statUpgradeAmount = statUpgradeItem.count + math.floor(statUpgradeItem.count / 10) * 3
	elseif statusName == "maxHealth" then
		statUpgradeAmount = statUpgradeItem.count
	else
		statUpgradeAmount = 0
	end

	for _, statusEffect in ipairs(statusList) do
		if statusEffect.stat ~= nil and statusEffect.stat == statusName then
			if statusName ~= "powerMultiplier" then
                statusEffect.amount = statusEffect.amount + statUpgradeAmount
            else
                statusEffect.baseMultiplier = statusEffect.baseMultiplier + statUpgradeAmount
            end
			statUpgraded = true
			break
		end
	end

	if not statUpgraded then
        if statusName ~= "powerMultiplier" then
		    table.insert(statusList, {stat = statusName, amount = statUpgradeAmount})
        else
            table.insert(statusList, {stat = statusName, baseMultiplier = statUpgradeAmount})
        end
	end

	return statusList
end

function die()

end