
local origInit = init
local origUninit = uninit
local checkingMod = "ztarbound"

-- Prevent the script from being called twice if it was patched into the player more than once for some reason
zbInited = false
zbUninited = false

function init(...)
	if origInit then
		origInit(...)
	end
	if zbInited then return end
	zbInited = true

	sb.logInfo("----- ZB player init -----")
	status.setStatusProperty("zb_updatewindow_error", nil)

	-- popping up the update window in a safe enviorment so everything else runs as it should in case of errors with the versioning file
	local passed, err = pcall(updateInfoWindow)
	if not passed then
		sb.logError("[ZB] ERROR INITIALIZING POPUP WINDOW\n%s", err)
		status.setStatusProperty("zb_updatewindow_error", checkingMod)
		player.interact("ScriptPane", "/zb/updateInfoWindow/updateInfoWindowError.config", player.id())
	end

	-- Add the scan interaction handler if its missing
	if not player.hasQuest("zb_scaninteraction") then
		sb.logInfo("Re-added 'zb_scaninteraction' quest")
		player.startQuest("zb_scaninteraction")
	end

	-- require "/zb/zb_util.lua"
	-- zbutil.DeepPrintTable(player)

	sb.logInfo("----- end ZB player init -----")
end

function updateInfoWindow()
	status.setStatusProperty("zb_updatewindow_pending", nil)
	local data = root.assetJson("/zb/updateInfoWindow/data.config")
	local versions = status.statusProperty("zb_updatewindow_versions", {})
	local world = world.type()
	local pending = {}

	for _, instance in ipairs(data.Data.ignoredInstances) do
		if world == instance then return end
	end

	sb.logInfo("[ZB] Mods using update info window and their versions:")
	for mod, modData in pairs(data) do
		checkingMod = mod
		if mod ~= "Data" then
			local text = root.assetJson(modData.file)
			sb.logInfo("-- %s   [%s]", mod, text.version)
			if text.version ~= versions[mod] then
				table.insert(pending, mod)
			end
		end
	end

	-- Version values are updated in the pane

	if #pending > 0 then
		status.setStatusProperty("zb_updatewindow_pending", pending)
		status.setStatusProperty("zb_updatewindow_versions", versions)
		player.interact("ScriptPane", "/zb/updateInfoWindow/updateInfoWindow.config")
	else
		status.setStatusProperty("zb_updatewindow_pending", nil)
	end
end

function uninit(...)
	if origUninit then
		origUninit(...)
	end
	if zbUninited then return end
	zbUninited = true

	world.sendEntityMessage(player.id(), "stopAltMusic", 2.0)
end