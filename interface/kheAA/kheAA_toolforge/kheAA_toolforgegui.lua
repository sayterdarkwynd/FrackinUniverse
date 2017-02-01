function init()
	self.functionalSlots = {
		head = {slot = 1, validType = "headarmor"},
		chest = {slot = 2, validType = "chestarmor"},
		legs = {slot = 3, validType = "legsarmor"},
		back = {slot = 4, validType = "backarmor"}
	}

	self.cosmeticSlots = {
		headCosmetic = {slot = 1, validType = "headarmor"},
		chestCosmetic = {slot = 2, validType = "chestarmor"},
		legsCosmetic = {slot = 3, validType = "legsarmor"},
		backCosmetic = {slot = 4, validType = "backarmor"}
	}
end

function craftButton()
	widget.setText("stat1", "10 Points");
	widget.setText("stat2", "10 HP");
	widget.setText("statName1", "Megapoints:");
	widget.setText("statName2", "Damage:");

end

function filter()
end

function equip(slotMap)
	local contents = widget.itemGridItems("itemGrid")
	for slotName, slotConfig in pairs(slotMap) do
		local item = contents[slotConfig.slot]
		if item == nil or root.itemType(item.name) == slotConfig.validType then
			world.containerSwapItems(pane.containerEntityId(), player.equippedItem(slotName), slotConfig.slot - 1)
			player.setEquippedItem(slotName, item)
		end
	end
end
