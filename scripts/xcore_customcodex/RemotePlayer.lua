-- PlayerReplicator
-- Replicates ALL player functions and exposes them as a message handler.

require("/scripts/messageutil.lua")

local OldInit = init

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
		if sb then sb.logWarn("Player attempted to learn codex, but held item name did not end in -codex! This could cause serious issues!") end
	else
		itemName = itemName:sub(1, -7)
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


function init()
	if OldInit then
		OldInit()
	end
	message.setHandler("xcodexLearnCodex", localHandler(LearnCodex))
	
	-- NEW: I want to also try to prepopulate the player's species's known codexes.
	local playerCfg = root.assetJson("/player.config")
	local defaultCdxArray = playerCfg.defaultCodexes
	local playerSpecies = player.species()
	local speciesDefaultCdx = defaultCdxArray[playerSpecies] or {}
	for _, cdx in pairs(speciesDefaultCdx) do
		LearnCodex(cdx .. "-codex") -- This is so that it doesn't complain about it not being a codex item.
	end
end