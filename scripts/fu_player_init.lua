
local origInit = init
local origUninit = uninit

function init()
	origInit()
	sb.logInfo("----- FU player init -----")
	
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
	
	message.setHandler("fu_key", function(_, _, requiredItem)
		if player.hasItem(requiredItem) then
			return true
		end
		return false
	end)
	
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
	
	sb.logInfo("Frackin' Universe version %s", data.version)
end

function uninit()
	local untieredLootboxes = player.hasCountOfItem({name = "fu_lootbox", parameters = {}}, true)
	if untieredLootboxes and untieredLootboxes > 0 then
		local threatLevel = roundNum(world.threatLevel())
		for i = 1, untieredLootboxes do
			player.consumeItem({name = "fu_lootbox", parameters = {}}, true, true)
			player.giveItem({name = "fu_lootbox", parameters = {level = threatLevel}})
		end
	end
	
	sb.logError("")
	sb.logError("Uninit found %s untiered lootboxes.", untieredLootboxes)
	sb.logError("")
	
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

function roundNum(num)
	local low = math.floor(num)
	local high = math.ceil(num)
	
	if math.abs(num - low) < math.abs(num - high) then
		if num < 0 then
			return low * -1
		else
			return low
		end
	else
		if num < 0 then
			return high * -1
		else
			return high
		end
	end
end