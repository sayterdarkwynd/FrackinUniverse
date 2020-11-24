-- PlayerReplicator
-- Replicates ALL player functions and exposes them as a message handler.

require("/scripts/messageutil.lua")
require("/scripts/xcore_customcodex/LearnCodexRoutine.lua") -- Defines LearnCodex(string name)

local OldInit = init

function init(...)
	if OldInit then
		OldInit(...)
	end
	message.setHandler("xcodexLearnCodex", localHandler(LearnCodex))
end

function postinit()
	-- NEW: I want to also try to prepopulate the player's species's known codexes.
	-- This is in postinit() because LearnCodex uses logging which requires access to sb (which is defined *after* init for some god-awful reason.)
	-- In case you don't know -- InitializationUtility.lua adds a postinit function.

	local playerCfg = root.assetJson("/player.config")
	local defaultCdxArray = playerCfg.defaultCodexes
	local playerSpecies = player.species()
	local speciesDefaultCdx = defaultCdxArray[playerSpecies] or {}
	for _, cdx in pairs(speciesDefaultCdx) do
		LearnCodex(cdx .. "-codex") -- This is so that it doesn't complain about it not being a codex item.
	end
end

-- Yes, this goes down here. Don't move it or you will cause postinit() to never run.
require("/scripts/xcore_customcodex/InitializationUtility.lua")