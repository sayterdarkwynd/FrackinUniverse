
local origInit = init

function init()
	origInit()
	
	local data = root.assetJson("/_FUversioning.config")
	if status.statusProperty("FUversion", "0") ~= data.version then
		status.setStatusProperty("FUversion", data.version)
		player.interact("ScriptPane", "/interface/scripted/fu_updateInfoWindow/updateInfoWindow.config", player.id())
	end
	
	sb.logInfo("Frackin' Universe version %s", data.version)
end