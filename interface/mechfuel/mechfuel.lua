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
  self.fuels = config.getParameter("fuels")
  self.fuelTypes = config.getParameter("fuelTypes")
  self.mechHornEnergyBoosts = config.getParameter("mechHornEnergyBoosts")
  self.planetId = player.worldId()
end



function update(dt)
  if self.disabled then return end
  
  if not world.entityExists(player.id()) then
    return
  end

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
	        local massTotal = (params.parts.body.stats.mechMass or 0) + (params.parts.booster.stats.mechMass or 0) + (params.parts.legs.stats.mechMass or 0) + (params.parts.leftArm.stats.mechMass or 0) + (params.parts.rightArm.stats.mechMass or 0)
		self.energyBoost = self.mechHornEnergyBoosts[params.parts.hornName] or 0
		-- check mass. If its too high, we reduce the amount of boosted energy given to the player to keep heavy mechs heavy, not energy batteries
		if massTotal > 22 then
		  self.energyBoost = self.energyBoost * (massTotal/50)
		end
	        self.maxFuel = ((100 + params.parts.body.energyMax) *(params.parts.body.stats.energyBonus or 1))  + (self.energyBoost or 0) 
	    end
    end
  end

  if self.maxFuel and self.currentFuel then  
	widget.setText("lblModuleCount", string.format("%.02f", math.floor(self.currentFuel)) .. " / " .. math.floor(self.maxFuel))
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
  
  if self.currentFuel > self.maxFuel then
    self.currentFuel = self.maxFuel
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
  local fuelBonus = 0
  local localFuelType = ""
  
  local fuelData = self.fuels[item.name]
  if fuelData then
    fuelMultiplier = fuelData.fuelMultiplier
    localFuelType = fuelData.fuelType 
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
  if swapItem and not self.fuels[swapItem.name] then
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
  
  local fuelData = self.fuels[currentItem.name]
  local effeciencyText = "Detected fuel type: ^<color>;<fuelName>^white;, Efficiency: x<fuelMultiplier>"	--Make json value
  local currentItemCfg = root.itemConfig(currentItem.name).config
  if fuelData then
    widget.setText("lblEfficiency", effeciencyText:gsub("<color>", fuelData.textColor or "white"):gsub("<fuelName>", currentItemCfg.shortdescription):gsub("<fuelMultiplier>", fuelData.fuelMultiplier))
  else
    widget.setText("lblEfficiency", "")
  end
end

function fuelCountPreview(item)


  
  if not item then
    widget.setText("lblModuleCount", string.format("%.02f", math.floor(self.currentFuel)) .. " / " .. math.floor(self.maxFuel))
    return
  end

  local fuelMultiplier = 1
  local textColor = "white"
  
  local fuelData = self.fuels[item.name]
  if fuelData then
    fuelMultiplier = fuelData.fuelMultiplier
    textColor = fuelData.textColor or textColor 
  end

  local addFuelCount = self.currentFuel + (item.count * fuelMultiplier)

  if addFuelCount > self.maxFuel then
    addFuelCount = self.maxFuel
  end

  widget.setText("lblModuleCount", "^" .. textColor .. ";" .. string.format("%.02f", addFuelCount) .. "^white; / " .. math.floor(self.maxFuel))
end

function setFuelTypeText(type)
  local textColor = ""
  local fuelTypeData = self.fuelTypes[type]
  if fuelTypeData then
    textColor = fuelTypeData.textColor       
  else
    textColor = nil
  end

  if textColor then
    widget.setText("lblFuelType", "CURRENT FUEL: ^" .. textColor .. ";" .. type)
  else
    widget.setText("lblFuelType", "CURRENT FUEL: ^red;EMPTY^reset;")
  end
end
