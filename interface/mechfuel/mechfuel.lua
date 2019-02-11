require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  local getUnlockedMessage = world.sendEntityMessage(player.id(), "mechUnlocked")
  if getUnlockedMessage:finished() and getUnlockedMessage:succeeded() then
    local unlocked = getUnlockedMessage:result()
    if not unlocked then
      self.disabled = true
      widget.setVisible("imgLockedOverlay", true)
      widget.setButtonEnabled("btnUpgrade", false)
	    widget.setText("lblLocked", "^red;Unauthorized user")
    else
      widget.setVisible("imgLockedOverlay", false)
    end
  else
    sb.logError("Mech fuel interface unable to check player mech enabled state!")
  end

  self.effeciencySet = false
end

function update(dt)
  if self.disabled then return end

  if not self.currentFuelMessage then
    local id = player.id()
    self.currentFuelMessage = world.sendEntityMessage(id, "getQuestFuelCount")
  end

  if self.currentFuelMessage and self.currentFuelMessage:finished() then
    if self.currentFuelMessage:succeeded() then
	  self.currentFuel = self.currentFuelMessage:result()
	end
	self.currentFuelMessage = nil
  end

  if not self.maxFuelMessage then
    local id = player.id()
    self.maxFuelMessage = world.sendEntityMessage(id, "getMechParams")
  end

  if self.maxFuelMessage and self.maxFuelMessage:finished() then
    if self.maxFuelMessage:succeeded() then
	    if self.maxFuelMessage:result() then
	      local params = self.maxFuelMessage:result()
	      self.maxFuel = params.parts.body.energyMax
	    end
	  end
  end

  if self.maxFuel and self.currentFuel then
    widget.setText("lblModuleCount", string.format("%.02f", self.currentFuel) .. " / " .. math.floor(self.maxFuel))
  end

  if self.setItemMessage and self.setItemMessage:finished() then
	  self.setItemMessage = nil
  end

  if not self.getItemMessage then
    local id = player.id()
    self.getItemMessage = world.sendEntityMessage(id, "getFuelSlotItem")
  end
  if self.getItemMessage and self.getItemMessage:finished() then
    if self.getItemMessage:succeeded() then
      local item = self.getItemMessage:result()
	    widget.setItemSlotItem("itemSlot_fuel", item)
      fuelCountPreview(item)

      if not self.efficiencySet then
        setEfficiencyText(item)
        self.efficiencySet = true
      end
	  end
	  self.getItemMessage = nil
  end

  if not self.fuelTypeMessage then
    local id = player.id()
    self.fuelTypeMessage = world.sendEntityMessage(id, "getFuelType")
  end
  if self.fuelTypeMessage and self.fuelTypeMessage:finished() then
    if self.fuelTypeMessage:succeeded() then
      local fuelType = self.fuelTypeMessage:result()
      self.currentFuelType = fuelType
      setFuelTypeText(fuelType)
    end
    self.fuelTypeMessage = nil
  end
end

function insertFuel()
  if self.disabled then return end

  swapItem("itemSlot_fuel")
end

function fuel()
  if self.disabled then return end

  local item = widget.itemSlotItem("itemSlot_fuel")
  if not item then return end
  local id = player.id()

  local fuelMultiplier = 1
  local localFuelType = ""

  if item.name == "liquidoil" then
    fuelMultiplier = 0.5
    localFuelType = "Oil"
  elseif item.name == "liquidfuel" or item.name == "solidfuel" then
    fuelMultiplier = 1
    localFuelType = "Erchius"
  elseif item.name == "liquidmechfuel" then
    fuelMultiplier = 2
    localFuelType = "Mech fuel"
  elseif item.name == "unrefinedliquidmechfuel" then
    fuelMultiplier = 1.5
    localFuelType = "Unrefined"
  end

  if self.currentFuelType and localFuelType ~= self.currentFuelType then
    widget.setText("lblEfficiency", "^red;The tank has a different type of fuel, empty it first.^white;")
    return
  end

  local addFuelCount = self.currentFuel + (item.count * fuelMultiplier)

  if addFuelCount > self.maxFuel then
    item.count = addFuelCount - self.maxFuel
	  if fuelMultiplier > 1 then
      item.count = (addFuelCount - self.maxFuel) / fuelMultiplier
    end
	  self.setItemMessage = world.sendEntityMessage(id, "setFuelSlotItem", item)
	  addFuelCount = self.maxFuel
  else
    self.setItemMessage = world.sendEntityMessage(id, "setFuelSlotItem", nil)
  end

  world.sendEntityMessage(id, "setFuelType", localFuelType)
  world.sendEntityMessage(id, "setQuestFuelCount", addFuelCount)
end

function swapItem(widgetName)
  local currentItem = widget.itemSlotItem(widgetName)
  local swapItem = player.swapSlotItem()
  if swapItem and not (swapItem.name == "liquidfuel"
  or swapItem.name == "solidfuel"
  or swapItem.name == "liquidoil"
  or swapItem.name == "liquidmechfuel"
  or swapItem.name == "unrefinedliquidmechfuel") then
    return
  end

  player.setSwapSlotItem(currentItem)
  widget.setItemSlotItem(widgetName, swapItem)

  setEfficiencyText(swapItem)

  local id = player.id()
  if not self.setItemMessage then
    self.setItemMessage = world.sendEntityMessage(id, "setFuelSlotItem", swapItem)
  end
end

function setEfficiencyText(currentItem)
  if not currentItem then
    widget.setText("lblEfficiency", "")
    return
  end

  if currentItem.name == "liquidfuel" or currentItem.name == "solidfuel" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#bf2fe2;Erchius^white;, Efficiency: full")
  elseif currentItem.name == "liquidoil" then
    widget.setText("lblEfficiency", "Detected fuel type: ^gray;Oil^white;, Efficiency: half")
  elseif currentItem.name == "liquidmechfuel" then
    widget.setText("lblEfficiency", "Detected fuel type: ^yellow;Mech fuel^white;, Efficiency: double")
  elseif currentItem.name == "unrefinedliquidmechfuel" then
    widget.setText("lblEfficiency", "Detected fuel type: ^orange;Unrefined fuel^white;, Efficiency: 1.5")
  else
    widget.setText("lblEfficiency", "")
  end
end

function fuelCountPreview(item)
  if not item then
    widget.setText("lblModuleCount", string.format("%.02f", self.currentFuel) .. " / " .. math.floor(self.maxFuel))
    return
  end

  local fuelMultiplier = 1
  local textColor = "white"

  if item.name == "liquidoil" then
    fuelMultiplier = 0.5
    textColor = "gray"
  elseif item.name == "liquidfuel" then
    fuelMultiplier = 1
    textColor = "#bf2fe2"
  elseif item.name == "liquidmechfuel" then
    fuelMultiplier = 2
    textColor = "yellow"
  elseif item.name == "unrefinedliquidmechfuel" then
    fuelMultiplier = 1.5
    textColor = "orange"
  end

  local addFuelCount = self.currentFuel + (item.count * fuelMultiplier)

  if addFuelCount > self.maxFuel then
    addFuelCount = self.maxFuel
  end

  widget.setText("lblModuleCount", "^" .. textColor .. ";" .. string.format("%.02f", addFuelCount) .. "^white; / " .. math.floor(self.maxFuel))
end

function setFuelTypeText(type)
  local textColor = ""
  if type == "Oil" then
    textColor = "gray"
  elseif type == "Erchius" then
    textColor = "#bf2fe2"
  elseif type == "Mech fuel" then
    textColor = "yellow"
  elseif type == "Unrefined" then
    textColor = "orange"
  else
    textColor = nil
  end

  if textColor then
    widget.setText("lblFuelType", "CURRENT FUEL TYPE: ^" .. textColor .. ";" .. type)
  else
    widget.setText("lblFuelType", "CURRENT FUEL TYPE: EMPTY")
  end
end
