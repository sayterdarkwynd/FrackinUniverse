
local origInit = init
local origUninit = uninit

function init()
	origInit()
	sb.logInfo("----- FU player init -----")
	
	-- popping up the update window in a safe enviorment so everything else runs as it should in case of errors with the versioning file
	local status, err = pcall(popupWindow)
	if not status then
		sb.logInfo("ERROR LOADING '/_FUversioning.config' FILE.")
		sb.logInfo("%s", err)
		player.interact("ScriptPane", "/interface/scripted/fu_updateInfoWindow/updateInfoWindowError.config", player.id())
	end
	sb.logInfo("")
	
	message.setHandler("fu_key", function(_, _, requiredItem)
		if player.hasItem(requiredItem) then
			return true
		end
		local essentialSlots = {"beamaxe", "wiretool", "painttool", "inspectiontool"}
		for _,slot in pairs (essentialSlots) do
			local essentialItem = player.essentialItem(slot)
			if essentialItem and essentialItem.name == requiredItem then
				return true
			end
		end
		return false
	end)
	
	if not player.hasQuest("fu_scaninteraction") then
		sb.logInfo("Readded 'fu_scaninteraction' quest")
		player.startQuest("fu_scaninteraction")
	end
	
	--[[
	local goods = {"foodgoods", "medicalgoods", "electronicgoods", "militarygoods"}
	for _, g in ipairs(goods) do
		local amount = player.hasCountOfItem({name = g})
		if amount > 0 then
			player.consumeItem({name = g, count = amount})
			player.addCurrency("fu"..g, amount)
			
			sb.logInfo("converted %s '%s' into '%s' currency", amount, g, "fu"..g)
		end
	end
	--]]
	
end

function popupWindow()
	local data = root.assetJson("/_FUversioning.config")
	if status.statusProperty("FUversion", "0") ~= data.version then
		local world = world.type()
		local ignore = false
		
		for _, instance in ipairs(data.ignoredInstances) do
			if world == instance then
				ignore = true
				break
			end
		end
		
		if not ignore then
			player.interact("ScriptPane", "/interface/scripted/fu_updateInfoWindow/updateInfoWindow.config", player.id())
		end
	end
	
	sb.logInfo("Frackin' Universe version %s", data.version)
end

function uninit()
	local untieredLootboxes = player.hasCountOfItem({name = "fu_lootbox", parameters = {}}, true)
	if untieredLootboxes and untieredLootboxes > 0 then
		local threatLevel = math.floor(world.threatLevel() + 0.5)
		for i = 1, untieredLootboxes do
			player.consumeItem({name = "fu_lootbox", parameters = {}}, true, true)
			player.giveItem({name = "fu_lootbox", parameters = {level = threatLevel}})
		end
	end
	
	origUninit()
end