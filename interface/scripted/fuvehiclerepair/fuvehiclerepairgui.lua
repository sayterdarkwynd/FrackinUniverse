require "/scripts/util.lua"
require "/scripts/interp.lua"

function init()
  self.chipRepairAmount = config.getParameter("chipRepairAmount")

  self.itemList = "itemScrollArea.itemList"

  self.vehicleItems = {}
  self.selectedItem = nil
  populateItemList()
end

function update(dt)
  populateItemList()
end

function repairCost(item)
  if item == nil then return 0 end


  local repairAmount = 1 - vehicleDurability(item)
  return math.ceil(repairAmount / self.chipRepairAmount)
end

function vehicleDurability(item)
  if item.parameters.filled ~= nil and item.parameters.filled == false then
    return 0.0
  end

  return item.parameters.vehicleStartHealthFactor or 1.0
end

function repairVehicle(item)
  local cost = repairCost(item)

  if player.consumeItem(item) then
    local consumed = player.consumeCurrency("money", cost)
    local repairedItem = copy(item)
    if consumed then
      repairedItem.parameters.vehicleStartHealthFactor = 1.0
      repairedItem.parameters.filled = true
      repairedItem.parameters.inventoryIcon = nil
    end
    player.giveItem(repairedItem)
  end
end

function populateItemList()
  local vehicleItems = player.itemsWithTag("vehiclecontroller")
  table.sort(vehicleItems, function(a, b)
    return vehicleDurability(a) < vehicleDurability(b)
  end)
  
  widget.setVisible("emptyLabel", #vehicleItems == 0)

  if not compare(vehicleItems, self.vehicleItems) then
    self.vehicleItems = vehicleItems
    widget.clearListItems(self.itemList)
    widget.setButtonEnabled("repairButton", false)

    for i,item in pairs(self.vehicleItems) do
      local config = root.itemConfig(item.name)

      local listItem = string.format("%s.%s", self.itemList, widget.addListItem(self.itemList))
      local name = config.config.shortdescription
      local icon = item.parameters.inventoryIcon or config.config.inventoryIcon
      icon = util.absolutePath(config.directory, icon)

      widget.setText(string.format("%s.itemName", listItem), name)
      widget.setImage(string.format("%s.itemIcon", listItem), icon)

      widget.setProgress(string.format("%s.durability", listItem), vehicleDurability(item))
      widget.setData(listItem, i)
    end

    self.selectedItem = nil
    showVehicle(nil)
  end
end

function showVehicle(item)
  local chips = player.currency("money")
  local enableButton = false

  if item and chips >= repairCost(item) then
    if chips > 0 then enableButton = true end

    widget.setText("chipCost", string.format("%s / %s", chips, repairCost(item)))
  else
    widget.setText("chipCost", string.format("%s / --", chips))
  end

  widget.setButtonEnabled("repairButton", enableButton)
end

function itemSelected()
  local listItem = widget.getListSelected(self.itemList)
  self.selectedItem = listItem

  if listItem then
    local itemData = widget.getData(string.format("%s.%s", self.itemList, listItem))
    local vehicleItem = self.vehicleItems[itemData]
    showVehicle(vehicleItem)
  end
end

function doRepair()
  if self.selectedItem then
    local selectedData = widget.getData(string.format("%s.%s", self.itemList, self.selectedItem))
    local vehicleItem = self.vehicleItems[selectedData]
    
    if vehicleItem then
      repairVehicle(vehicleItem)
    end
    populateItemList()
  end
end