require "/scripts/vec2.lua"

function init()
	-- This code could probs be optimised quite a bit, but don't really feel like it atm
	local playerCfg = root.assetJson("/player.config")
	local defaultUnlocks = playerCfg.defaultBlueprints.tier1
	local unlocks = {}
	for _, item in ipairs(defaultUnlocks) do
		local itemName = item.item or item.name
		if itemName then
			unlocks[itemName] = true
		end
	end
	local requiredUnlocks = config.getParameter("defaultUnlocks", {})
	local missingUnlocks = {}
	missingString = "If the the text doesn't fit in the popup look at the log.\nMissing the unlocks for: "
	for _, item in ipairs(requiredUnlocks) do
		if not unlocks[item] then
			table.insert(missingUnlocks, item)
			missingString = missingString .. item .. ", "
		end
	end
	missingString = missingString:sub(1, -3)
	local requiredUnlocksTable = {}
	for _, item in ipairs (requiredUnlocks) do
		requiredUnlocksTable[item] = true
	end
	local extraUnlocks = {}
	missingString = missingString .. "\nUnlocks where vanilla ones should be: "
	for i = 1, #requiredUnlocks do
		local itemCfg = defaultUnlocks[i]
		local item = defaultUnlocks[i].item or defaultUnlocks[i].name
		if item and not requiredUnlocksTable[item] then
			table.insert(extraUnlocks, item)
			missingString = missingString .. item .. ", "
		end
	end
	missingString = missingString:sub(1, -3)
end

function update(dt, fireMode, shiftHeld)
	
end

function activate(fireMode, shiftHeld)
	player.interact("ShowPopup", {message = missingString})
	sb.logInfo(missingString)
	--sb.logInfo(sb.printJson(missingUnlocks, 1))
	--sb.logInfo(sb.printJson(extraUnlocks, 1))
	fired = true
end