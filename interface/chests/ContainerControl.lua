-- Appended by Xan the Dragon
-- Main controller script for the "Read All" button added by /chest/cdx/chest<slots>.config

----------------------------------------------
------ Duplicated from RemotePlayer.lua ------
----------------------------------------------

local function TableAlreadyContains(tbl, entry)
	for _, value in pairs(tbl) do
		if value[1] == entry[1] and value[2] == entry[2] then
			return true
		end
	end
	return false
end

local function LearnCodex(itemName)
	local existingKnownEntries = player.getProperty("xcodex.knownCodexEntries") or {}
	local data = root.itemConfig(itemName)		
	if itemName:sub(-6) ~= "-codex" then
		return -- Abort. Don't warn and try to continue anyway. This condition was already checked anyway.
	else
		itemName = itemName:sub(1, -7)
	end
	
	-- Now one more thing I want to add here for ContainerControl and NOT in stock RemotePlayer is determining if the item is actually a codex.
	-- Knowing people, some guy is gonna make a gun or something and name it "roflcopter-codex", and if that passes this gateway, shit's gonna hit the fan.
	-- The actual codex UI protects against this but it's gonna be stored as a readable codex which means doing that check every time the player opens the UI. Not fun!
	local foundCodexFile = pcall(function ()
		root.assetJson(data.directory .. itemName .. ".codex")
	end)
	
	if not foundCodexFile then
		if sb then sb.logWarn("An item ended in -codex but was NOT a codex! Ignoring this item.") end
		return
	end
	
	-- This is for sanity checking. The interface itself will actually remove null codex entries from player data persistence.
	local codexCache = {tostring(itemName), tostring(data.directory)}
	
	-- If our internal cache here says we don't know it then we need to learn it.
	if not TableAlreadyContains(existingKnownEntries, codexCache) then
		table.insert(existingKnownEntries, codexCache)
		player.setProperty("xcodex.knownCodexEntries", existingKnownEntries)
		if sb then sb.logInfo("Player has learned codex " .. table.concat(codexCache, ", ") .. ".") end
	else
		if sb then sb.logInfo("Player attempted to learn codex " .. table.concat(codexCache, ", ") .. " but they already know it in the new registry.") end
	end
end

----------------------------------------------
----------------------------------------------
----------------------------------------------

function CodexButtonClicked()
	--player.interact("ScriptPane", "/interface/scripted/xcustomcodex/xcodexui.config", player.id())
	local items = widget.itemGridItems("itemGrid")
	for index, item in pairs(items) do
		local itemName = item.name
		-- Simple test: Does it end in -codex? We can easily scrap items that aren't codexes this way.
		 if itemName:sub(-6) == "-codex" then
			LearnCodex(itemName)
		 end
	end
	widget.playSound("/sfx/interface/item_equip.ogg") -- Give the player some feedback that they learned the entries.
end

-- gg ez