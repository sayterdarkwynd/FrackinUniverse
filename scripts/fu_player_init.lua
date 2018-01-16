
local origInit = init

function init()
	origInit()
	sb.logInfo("----- FU player init -----")
	
	local data = root.assetJson("/_FUversioning.config")
	if status.statusProperty("FUversion", "0") ~= data.version then
		status.setStatusProperty("FUversion", data.version)
		player.interact("ScriptPane", "/interface/scripted/fu_updateInfoWindow/updateInfoWindow.config", player.id())
	end
	
	local goods = {"foodgoods", "medicalgoods", "electronicgoods", "militarygoods"}
	for _, g in ipairs(goods) do
		local amount = player.hasCountOfItem({name = g})
		if amount > 0 then
			player.consumeItem({name = g, count = amount})
			player.addCurrency("fu"..g, amount)
			
			sb.logInfo("converted %s '%s' into '%s' currency", amount, g, "fu"..g)
		end
	end
	
	sb.logInfo("Frackin' Universe version %s", data.version)
end