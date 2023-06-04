require "/scripts/vec2.lua"

function init()
	local playerCfg = root.assetJson("/player.config")
	local defaultUnlocks = playerCfg.defaultBlueprints.tier1
	local unlocks = {}
	local strings = config.getParameter("strings", {})
	for _, item in ipairs(defaultUnlocks) do
		local itemName = item.item or item.name
		if itemName then
			unlocks[itemName] = true
		end
	end
	local requiredUnlocks = config.getParameter("defaultUnlocks", {})
	local requiredUnlocksTable = {}
	local missingUnlocks = {}
	for _, item in ipairs(requiredUnlocks) do
		requiredUnlocksTable[item] = true
		if not unlocks[item] then
			table.insert(missingUnlocks, item)
		end
	end
	popupString = strings.numMissingUnlocks:gsub("<numMissing>", "<colour>" .. tostring(#missingUnlocks) .. "^reset;")
	if #missingUnlocks > 0 then
		popupString = popupString:gsub("<colour>", "^red;")
		popupString = popupString .. "\n" .. strings.missingUnlocksPresent
		logString = strings.logString
		local issueUnlocks = {}
		for _, item in ipairs (defaultUnlocks) do
			local itemName = item.item or item.name
			if itemName then
				if requiredUnlocksTable[itemName] then
					break;
				else
					table.insert(issueUnlocks, itemName)
				end
			end
		end
		logString = logString .. sb.printJson(issueUnlocks, 1)
	else
		popupString = popupString:gsub("<colour>", "^green;")
	end
end

function update(dt, fireMode, shiftHeld)

end

function activate(fireMode, shiftHeld)
	player.interact("ShowPopup", {message = popupString})
	if logString then
		sb.logInfo(logString)
	end
	fired = true
end