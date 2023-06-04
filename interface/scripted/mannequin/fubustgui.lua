function init()
  self.functionalSlot = {slot = 1, validType = "headarmor"}

  self.cosmeticSlot = {slot = 1, validType = "headarmor"}
end

--function swapGender()
--  world.sendEntityMessage(pane.containerEntityId(), "swapGender")
--end

function equipFunctional()
  equip("head", self.functionalSlot)
end

function equipCosmetic()
  equip("headCosmetic", self.cosmeticSlot)
end

function equip(slotName, slotConfig)
  local contents = widget.itemGridItems("itemGrid")
  local item = contents[slotConfig.slot]
  if item == nil or root.itemType(item.name) == slotConfig.validType then
    world.containerSwapItems(pane.containerEntityId(), player.equippedItem(slotName), slotConfig.slot-1)
    player.setEquippedItem(slotName, item)
  end
end
