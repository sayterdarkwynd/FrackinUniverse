require "/vehicles/modularmech/mechpartmanager.lua"
require "/scripts/util.lua"
require "/scripts/vec2.lua"

previewStates = {
  power = "active",
  boost = "idle",
  frontFoot = "preview",
  backFoot = "preview",
  leftArm = "idle",
  rightArm = "idle"
}

function init()
  self.disabledText = config.getParameter("disabledText")
  self.completeText = config.getParameter("completeText")
  self.incompleteText = config.getParameter("incompleteText")

  self.energyFormat = config.getParameter("energyFormat")
  self.drainFormat = config.getParameter("drainFormat")
  self.massFormat = config.getParameter("massFormat")
  self.imageBasePath = config.getParameter("imageBasePath")

  local getUnlockedMessage = world.sendEntityMessage(player.id(), "mechUnlocked")
  if getUnlockedMessage:finished() and getUnlockedMessage:succeeded() then
    local unlocked = getUnlockedMessage:result()
    if not unlocked then
      self.disabled = true
      widget.setVisible("imgDisabledOverlay", true)
      widget.setButtonEnabled("btnPrevPrimaryColor", false)
      widget.setButtonEnabled("btnNextPrimaryColor", false)
      widget.setButtonEnabled("btnPrevSecondaryColor", false)
      widget.setButtonEnabled("btnNextSecondaryColor", false)
    else
      widget.setVisible("imgDisabledOverlay", false)
    end
  else
    sb.logError("Mech assembly interface unable to check player mech enabled state!")
  end

  self.partManager = MechPartManager:new()

  self.itemSet = {}
  local getItemSetMessage = world.sendEntityMessage(player.id(), "getMechItemSet")
  if getItemSetMessage:finished() and getItemSetMessage:succeeded() then
    self.itemSet = getItemSetMessage:result()
  else
    sb.logError("Mech assembly interface unable to fetch player mech parts!")
  end

  self.primaryColorIndex = 0
  self.secondaryColorIndex = 0
  local getColorIndexesMessage = world.sendEntityMessage(player.id(), "getMechColorIndexes")
  if getColorIndexesMessage:finished() and getColorIndexesMessage:succeeded() then
    local res = getColorIndexesMessage:result()
    self.primaryColorIndex = res.primary
    self.secondaryColorIndex = res.secondary
  else
    sb.logError("Mech assembly interface unable to fetch player mech paint colors!")
  end

  self.previewCanvas = widget.bindCanvas("cvsPreview")

  for partType, itemDescriptor in pairs(self.itemSet) do
    widget.setItemSlotItem("itemSlot_" .. partType, itemDescriptor)
  end

  widget.setImage("imgPrimaryColorPreview", colorPreviewImage(self.primaryColorIndex))
  widget.setImage("imgSecondaryColorPreview", colorPreviewImage(self.secondaryColorIndex))

  updatePreview()
  updateComplete()
end

function update(dt)

end

function swapItem(widgetName)
  if self.disabled then return end

  local partType = string.sub(widgetName, 10)

  local currentItem = self.itemSet[partType]
  local swapItem = player.swapSlotItem()

  if not swapItem or self.partManager:partConfig(partType, swapItem) then
    player.setSwapSlotItem(currentItem)
    widget.setItemSlotItem(widgetName, swapItem)
    self.itemSet[partType] = swapItem

    itemSetChanged()
  end
end

function itemSetChanged()
  world.sendEntityMessage(player.id(), "setMechItemSet", self.itemSet)
  updatePreview()
  updateComplete()
end

function nextPrimaryColor()
  self.primaryColorIndex = self.partManager:validateColorIndex(self.primaryColorIndex + 1)
  colorSelectionChanged()
end

function prevPrimaryColor()
  self.primaryColorIndex = self.partManager:validateColorIndex(self.primaryColorIndex - 1)
  colorSelectionChanged()
end

function nextSecondaryColor()
  self.secondaryColorIndex = self.partManager:validateColorIndex(self.secondaryColorIndex + 1)
  colorSelectionChanged()
end

function prevSecondaryColor()
  self.secondaryColorIndex = self.partManager:validateColorIndex(self.secondaryColorIndex - 1)
  colorSelectionChanged()
end

function colorSelectionChanged()
  widget.setImage("imgPrimaryColorPreview", colorPreviewImage(self.primaryColorIndex))
  widget.setImage("imgSecondaryColorPreview", colorPreviewImage(self.secondaryColorIndex))
  world.sendEntityMessage(player.id(), "setMechColorIndexes", self.primaryColorIndex, self.secondaryColorIndex)
  updatePreview()
end

function updateComplete()
  if self.disabled then
    widget.setVisible("imgIncomplete", true)
    widget.setText("lblStatus", self.disabledText)
  elseif self.partManager:itemSetComplete(self.itemSet) then
    widget.setVisible("imgIncomplete", false)
    widget.setText("lblStatus", self.completeText)
  else
    widget.setVisible("imgIncomplete", true)
    widget.setText("lblStatus", self.incompleteText)
  end

  for _, partName in ipairs(self.partManager.requiredParts) do
    widget.setVisible("imgMissing_"..partName, not self.itemSet[partName])
  end
end

function colorPreviewImage(colorIndex)
  if colorIndex == 0 then
    return self.imageBasePath .. "paintbar_default.png"
  else
    local img = self.imageBasePath .. "paintbar.png"
    local toColors = self.partManager.paletteConfig.swapSets[colorIndex]
    for i, fromColor in ipairs(self.partManager.paletteConfig.primaryMagicColors) do
      img = string.format("%s?replace=%s=%s", img, fromColor, toColors[i])
    end
    return img
  end
end

function updatePreview()
  -- assemble vehicle and animation config
  local params = self.partManager:buildVehicleParameters(self.itemSet, self.primaryColorIndex, self.secondaryColorIndex)
  local animationConfig = root.assetJson("/vehicles/modularmech/modularmech.animation")
  util.mergeTable(animationConfig, params.animationCustom)

  -- build list of parts to preview
  local previewParts = {}
  for partName, partConfig in pairs(animationConfig.animatedParts.parts) do
    local partImageSet = params.partImages
    if partName:sub(1, 7) == "leftArm" and params.parts.leftArm and params.parts.leftArm.backPartImages then
      partImageSet = util.replaceTag(params.parts.leftArm.backPartImages, "armName", "leftArm")
    elseif partName:sub(1, 7) == "rightArm" and params.parts.rightArm and params.parts.rightArm.backPartImages then
      partImageSet = util.replaceTag(params.parts.rightArm.frontPartImages, "armName", "rightArm")
    end

    if partImageSet[partName] and partImageSet[partName] ~= "" then
      local partProperties = partConfig.properties or {}
      if partConfig.partStates then
        for stateName, stateConfig in pairs(partConfig.partStates) do
          if previewStates[stateName] and stateConfig[previewStates[stateName]] then
            partProperties = util.mergeTable(partProperties, stateConfig[previewStates[stateName]].properties or {})
            break
          end
        end
      end

      if partProperties.image then
        local partImage = "/vehicles/modularmech/" .. util.replaceTag(partProperties.image, "partImage", partImageSet[partName])
        table.insert(previewParts, {
            centered = partProperties.centered,
            zLevel = partProperties.zLevel or 0,
            image = partImage,
            offset = vec2.mul(partProperties.offset or {0, 0}, 8)
          })
      end
    end
  end

  table.sort(previewParts, function(a, b) return a.zLevel < b.zLevel end)

  -- replace directive tags in preview images
  previewParts = util.replaceTag(previewParts, "directives", "")
  for partName, directives in pairs(params.partDirectives) do
    previewParts = util.replaceTag(previewParts, partName.."Directives", directives)
  end

  -- draw preview images
  self.previewCanvas:clear()

  local canvasCenter = vec2.mul(widget.getSize("cvsPreview"), 0.5)

  for _, part in ipairs(previewParts) do
    local pos = vec2.add(canvasCenter, part.offset)
    self.previewCanvas:drawImage(part.image, pos, nil, nil, part.centered)
  end

  if self.partManager:itemSetComplete(self.itemSet) then
    widget.setVisible("imgEnergyBar", true)
    widget.setVisible("lblEnergy", true)
    widget.setVisible("lblDrain", true)
    widget.setVisible("lblMass", true)
    
    local energyMax = params.parts.body.energyMax
    local energyDrain = params.parts.body.energyDrain + params.parts.leftArm.energyDrain + params.parts.rightArm.energyDrain
    widget.setText("lblEnergy", string.format(self.energyFormat, energyMax))
    widget.setText("lblDrain", string.format(self.drainFormat, energyDrain))

    local mechMass = (params.parts.body.stats.mechMass or 0) + (params.parts.booster.stats.mechMass or 0) + (params.parts.legs.stats.mechMass or 0) + (params.parts.leftArm.stats.mechMass or 0) + (params.parts.rightArm.stats.mechMass or 0)  

    widget.setText("lblMass", string.format(self.massFormat, mechMass))
  else
    widget.setVisible("imgEnergyBar", false)
    widget.setVisible("lblEnergy", false)
    widget.setVisible("lblDrain", false)
    widget.setVisible("lblMass", false)
  end
end
