
local origInit = init
local origUninit = uninit

function init()
	origInit()
	sb.logInfo("----- FU player init -----")
	
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