require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  self.playerId = player.id()

  self.timer = 0
  self.itemsLeft = 0
  self.maxTimer = 10
end

function update(dt)
  if not self.currentInputItemMessage then
    self.currentInputItemMessage = world.sendEntityMessage(self.playerId, "getRefineryInputItem")
  end
  if self.currentInputItemMessage and self.currentInputItemMessage:finished() then
    if self.currentInputItemMessage:succeeded() then
      widget.setItemSlotItem("itemSlot_input", self.currentInputItemMessage:result())
    end
    self.currentInputItemMessage = nil
  end

  if not self.currentOutputItemMessage then
    self.currentOutputItemMessage = world.sendEntityMessage(self.playerId, "getRefineryOutputItem")
  end
  if self.currentOutputItemMessage and self.currentOutputItemMessage:finished() then
    if self.currentOutputItemMessage:succeeded() then
      widget.setItemSlotItem("itemSlot_output", self.currentOutputItemMessage:result())
    end
    self.currentOutputItemMessage = nil
  end


  if self.itemsLeft > 0 then
    widget.setText("toggleCrafting", "Cancel")
    self.disable = true
    self.timer = self.timer + 1
    widget.setProgress("progressArrow", self.timer * 0.1)
    if self.timer == self.maxTimer then
      self.timer = 0
      widget.setProgress("progressArrow", 0)
      self.itemsLeft = self.itemsLeft - 1
      craftItem()
    end
  else
    self.disable = false
    widget.setText("toggleCrafting", "Distill")
    widget.setProgress("progressArrow", 0)
  end


end

function refine()
  if self.disable then
    self.itemsLeft = 0
    self.timer = 0
    return
  end

  local item = widget.itemSlotItem("itemSlot_input")
  if not item or (item and item.count == 1) then return end

  self.itemsLeft = math.floor(item.count * 0.5)
end

function insertFuel()
  if self.disable then return end

  swapItem("itemSlot_input")
end

function getFuel()
  swapItem("itemSlot_output", true)
end

function craftItem()
  local item = widget.itemSlotItem("itemSlot_input")

  local outputItem = widget.itemSlotItem("itemSlot_output")

  if not outputItem then
    outputItem = { name = "unrefinedliquidmechfuel", amount = 1 }
  elseif outputItem and outputItem.count < 1000 then
    outputItem.count = outputItem.count + 1
  elseif outputItem and outputItem.count == 1000 then
    self.itemsLeft = 0
    return
  end

  if item.count > 2 then
    item.count = item.count - 2
  else
    item = nil
  end

  world.sendEntityMessage(self.playerId, "setRefineryInputItem", item)
  world.sendEntityMessage(self.playerId, "setRefineryOutputItem", outputItem)
end

function swapItem(widgetName, output)
  local currentItem = widget.itemSlotItem(widgetName)
  local swapItem = player.swapSlotItem()
  if swapItem and swapItem.name == "liquidoil" and not output then
    player.setSwapSlotItem(currentItem)
    widget.setItemSlotItem(widgetName, swapItem)
  elseif not swapItem and not output then
    player.setSwapSlotItem(currentItem)
    widget.setItemSlotItem(widgetName, swapItem)
  elseif output then
    if currentItem then
      player.setSwapSlotItem(currentItem)
    end
    widget.setItemSlotItem(widgetName, nil)
  end

  currentItem = widget.itemSlotItem(widgetName)
  local id = player.id()
  if output then
    world.sendEntityMessage(id, "setRefineryOutputItem", currentItem)
  else
    world.sendEntityMessage(id, "setRefineryInputItem", currentItem)
  end
end

function updateProgress(progress)
  widget.setProgress("progressArrow", progress)
end
