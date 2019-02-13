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
	      
	        self.energyBoost = 0
	        local massTotal = (params.parts.body.stats.mechMass or 0) + (params.parts.booster.stats.mechMass or 0) + (params.parts.legs.stats.mechMass or 0) + (params.parts.leftArm.stats.mechMass or 0) + (params.parts.rightArm.stats.mechMass or 0)
		if params.parts.hornName == 'mechenergyfield' then 
		  self.energyBoost = 100
		elseif params.parts.hornName == 'mechenergyfield2' then 
		  self.energyBoost = 200
		elseif params.parts.hornName == 'mechenergyfield3' then 
		  self.energyBoost = 300
		elseif params.parts.hornName == 'mechenergyfield4' then 
		  self.energyBoost = 400
		elseif params.parts.hornName == 'mechenergyfield5' then 
		  self.energyBoost = 500
		end   
	        if massTotal > 22 then
	          self.energyBoost = self.energyBoost * (massTotal/50)
	        end	
	        
	      self.maxFuel = 100 + params.parts.body.energyMax *(params.parts.body.stats.energyBonus or 1)  + (self.energyBoost)
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
  elseif item.name == "uraniumrod" then
    fuelMultiplier = 2
    localFuelType = "Isotope"    
  elseif item.name == "plutoniumrod" then
    fuelMultiplier = 1.5
    localFuelType = "Isotope"    
  elseif item.name == "neptuniumrod" then
    fuelMultiplier = 1.5
    localFuelType = "Isotope"     
  elseif item.name == "thoriumrod" then
    fuelMultiplier = 1.65
    localFuelType = "Isotope"    
  elseif item.name == "enricheduranium" then
    fuelMultiplier = 3
    localFuelType = "Isotope" 
  elseif item.name == "enrichedplutonium" then
    fuelMultiplier = 2.5
    localFuelType = "Isotope"   
  elseif item.name == "ultronium" then
    fuelMultiplier = 25
    localFuelType = "Isotope"     
  -- rare fuels  
  elseif item.name == "precursorfuelcell" then
    fuelMultiplier = 250
    localFuelType = "Quantum"
  elseif item.name == "precursorfluid" then
    fuelMultiplier = 3.5
    localFuelType = "Quantum"
  -- Cores. Provide high energy value AND bonus energy that goes above the maxLimit  
  elseif item.name == "powercore" then
    fuelMultiplier = 500
    localFuelType = "Core"
  elseif item.name == "moltencore" then
    fuelMultiplier = 600
    localFuelType = "Core"
  elseif item.name == "particlecore" then
    fuelMultiplier = 700
    localFuelType = "Core"    
  elseif item.name == "nuclearcore" then
    fuelMultiplier = 800
    localFuelType = "Core"
  elseif item.name == "precursorcore" then
    fuelMultiplier = 900
    localFuelType = "Core"    
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
  or swapItem.name == "unrefinedliquidmechfuel"
  or swapItem.name == "uraniumrod"
  or swapItem.name == "plutoniumrod"
  or swapItem.name == "neptuniumrod"
  or swapItem.name == "thoriumrod"   
  or swapItem.name == "enricheduranium"
  or swapItem.name == "enrichedplutonium"
  or swapItem.name == "ultronium"
  or swapItem.name == "precursorfuelcell"
  or swapItem.name == "precursorfluid"   
  or swapItem.name == "powercore"
  or swapItem.name == "moltencore"
  or swapItem.name == "particlecore"  
  or swapItem.name == "nuclearcore"
  or swapItem.name == "precursorcore") then
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
    widget.setText("lblEfficiency", "Detected fuel type: ^#bf2fe2;Erchius^white;, Efficiency: x1.0")
  elseif currentItem.name == "liquidoil" then
    widget.setText("lblEfficiency", "Detected fuel type: ^gray;Oil^white;, Efficiency: x0.5")
  elseif currentItem.name == "liquidmechfuel" then
    widget.setText("lblEfficiency", "Detected fuel type: ^yellow;Mech fuel^white;, Efficiency: x2")
  elseif currentItem.name == "unrefinedliquidmechfuel" then
    widget.setText("lblEfficiency", "Detected fuel type: ^orange;Unrefined fuel^white;, Efficiency: x1.5")
  elseif currentItem.name == "uraniumrod" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#fcff00;Uranium^white;, Efficiency: x2.0")
  elseif currentItem.name == "plutoniumrod" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#fcff00;Plutonium^white;, Efficiency: x1.5")
  elseif currentItem.name == "neptuniumrod" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#fcff00;Neptunium^white;, Efficiency: x1.5")
  elseif currentItem.name == "thoriumrod" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#fcff00;Thorium^white;, Efficiency: x1.65")
  elseif currentItem.name == "enricheduranium" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#fcff00;Enriched Uranium^white;, Efficiency: x3")    
  elseif currentItem.name == "enrichedplutonium" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#fcff00;Enriched Plutonium^white;, Efficiency: x2.5")
  elseif currentItem.name == "ultronium" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#fcff00;Ultronium^white;, Efficiency: x25")    
  elseif currentItem.name == "precursorfuelcell" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#00e3ff;Precursor Cell^white;, Efficiency: x250")
  elseif currentItem.name == "precursorfluid" then
    widget.setText("lblEfficiency", "Detected fuel type: ^#00e3ff;Quantum Fluid^white;, Efficiency: x3.5")
  elseif currentItem.name == "powercore" then
    widget.setText("lblEfficiency", "Detected fuel type: ^orange;Power Core^white;, Efficiency: x500")
  elseif currentItem.name == "moltencore" then
    widget.setText("lblEfficiency", "Detected fuel type: ^orange;Molten Core^white;, Efficiency: x600")
  elseif currentItem.name == "particlecore" then
    widget.setText("lblEfficiency", "Detected fuel type: ^orange;Particle Core^white;, Efficiency: x700")
  elseif currentItem.name == "nuclearcore" then
    widget.setText("lblEfficiency", "Detected fuel type: ^orange;Nuclear Core^white;, Efficiency: x800")
  elseif currentItem.name == "precursorcore" then
    widget.setText("lblEfficiency", "Detected fuel type: ^orange;Precursor Core^white;, Efficiency: x900")    
  else
    widget.setText("lblEfficiency", "")
  end
end

function fuelCountPreview(item)

  if self.currentFuel > self.maxFuel then
  self.currentFuel = self.maxFuel
  end    
  if not item then
    widget.setText("lblModuleCount", string.format("%.02f", math.floor(self.currentFuel)) .. " / " .. math.floor(self.maxFuel))
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
  elseif item.name == "uraniumrod" then
    fuelMultiplier = 2
    textColor = "#fcff00"
  elseif item.name == "plutoniumrod" then
    fuelMultiplier = 1.5
    textColor = "#fcff00"
  elseif item.name == "enricheduranium" then
    fuelMultiplier = 3
    textColor = "#fcff00"
  elseif item.name == "enrichedplutonium" then
    fuelMultiplier = 2.5
    textColor = "#fcff00"
  elseif item.name == "ultronium" then
    fuelMultiplier = 25
    textColor = "#fcff00"    
  elseif item.name == "neptuniumrod" then
    fuelMultiplier = 1.5
    textColor = "#fcff00"
  elseif item.name == "thoriumrod" then
    fuelMultiplier = 1.65
    textColor = "#fcff00"
  elseif item.name == "precursorfuelcell" then
    fuelMultiplier = 250
    textColor = "00e3ff"
  elseif item.name == "precursorfluid" then
    fuelMultiplier = 3.5
    textColor = "00e3ff"
  elseif item.name == "powercore" then
    fuelMultiplier = 500
    textColor = "green"    
  elseif item.name == "moltencore" then
    fuelMultiplier = 600
    textColor = "green"
  elseif item.name == "particlecore" then
    fuelMultiplier = 700
    textColor = "green"
  elseif item.name == "nuclearcore" then
    fuelMultiplier = 800
    textColor = "green"
  elseif item.name == "precursorcore" then
    fuelMultiplier = 900
    textColor = "green"      
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
  elseif type == "Isotope" then
    textColor = "#fcff00"
  elseif type == "Quantum" then
    textColor = "#00e3ff"
  elseif type == "Core" then
    textColor = "green"       
  else
    textColor = nil
  end

  if textColor then
    widget.setText("lblFuelType", "CURRENT FUEL TYPE: ^" .. textColor .. ";" .. type)
  else
    widget.setText("lblFuelType", "CURRENT FUEL TYPE: EMPTY")
  end
end
