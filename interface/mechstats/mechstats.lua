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
  local mechParamsMessage = world.sendEntityMessage(player.id(), "getMechParams")
  local mechParams = mechParamsMessage:result()

  local getUnlockedMessage = world.sendEntityMessage(player.id(), "mechUnlocked")
  if getUnlockedMessage:finished() and getUnlockedMessage:succeeded() then
    local unlocked = getUnlockedMessage:result()
    if not unlocked then
      self.disabled = true
      widget.setText("lblStatus", "^red;Unauthorized user")
      widget.setVisible("imgDisabledOverlay", true)
      widget.setVisible("radioLoadouts", false)
      return
    else
      widget.setVisible("imgDisabledOverlay", false)
    end
  end

  self.partManager = MechPartManager:new()

  self.itemSet = {}
  local getItemSetMessage = world.sendEntityMessage(player.id(), "getMechItemSet")
  if getItemSetMessage:finished() and getItemSetMessage:succeeded() then
    self.itemSet = getItemSetMessage:result()
  else
    sb.logError("Mech stats interface unable to fetch player mech parts!")
  end

  self.primaryColorIndex = 0
  self.secondaryColorIndex = 0
  local getColorIndexesMessage = world.sendEntityMessage(player.id(), "getMechColorIndexes")
  if getColorIndexesMessage:finished() and getColorIndexesMessage:succeeded() then
    local res = getColorIndexesMessage:result()
    self.primaryColorIndex = res.primary
    self.secondaryColorIndex = res.secondary
  else
    sb.logError("Mech stats interface unable to fetch player mech paint colors!")
  end

  self.previewCanvas = widget.bindCanvas("cvsPreview")

  for partType, itemDescriptor in pairs(self.itemSet) do
    widget.setItemSlotItem("itemSlot_" .. partType, itemDescriptor)
  end

  self.loadoutsChanged = true

  updatePreview()
end

function update(dt)
  if self.disabled then return end
  if not world.entityExists(player.id()) then return end

  if not self.mechDeployedMessage then
    self.mechDeployedMessage = world.sendEntityMessage(player.id(), "isMechDeployed")
  end
  if self.mechDeployedMessage and self.mechDeployedMessage:finished() then
    if self.mechDeployedMessage:succeeded() then
      self.mechDeployed = self.mechDeployedMessage:result()

      if self.mechDeployed then
        widget.setOptionEnabled("radioLoadouts", 1, false)
        widget.setOptionEnabled("radioLoadouts", 2, false)
        widget.setOptionEnabled("radioLoadouts", 3, false)
      else
        widget.setOptionEnabled("radioLoadouts", 1, true)
        widget.setOptionEnabled("radioLoadouts", 2, true)
        widget.setOptionEnabled("radioLoadouts", 3, true)
      end
    end

    self.mechDeployedMessage = nil
  end

  if not self.loadoutsMessage and self.loadoutsChanged then
    self.loadoutsMessage = world.sendEntityMessage(player.id(), "getLoadouts")
  end

  if self.loadoutsMessage and self.loadoutsMessage:finished() then
    if self.loadoutsMessage:succeeded() then
      self.loadouts = self.loadoutsMessage:result()

      local loadoutNum = self.loadouts.currentLoadout or 1

      self.chips = self.loadouts["chips" .. loadoutNum]

      widget.setSelectedOption("radioLoadouts", self.loadouts.currentLoadout)
      if loadoutNum == 1 then
        world.sendEntityMessage(player.id(), "setMechItemSet", self.loadouts.loadout1, self.chips)
        self.itemSet = self.loadouts.loadout1
      elseif loadoutNum == 2 then
        world.sendEntityMessage(player.id(), "setMechItemSet", self.loadouts.loadout2, self.chips)
        self.itemSet = self.loadouts.loadout2
      elseif loadoutNum == 3 then
        world.sendEntityMessage(player.id(), "setMechItemSet", self.loadouts.loadout3, self.chips)
        self.itemSet = self.loadouts.loadout3
      end

      if not self.itemSet then
        self.itemSet = {}
      end

      world.sendEntityMessage(player.id(), "setMechLoadoutItemSetChanged", true)

      for chipName,_ in pairs({chip1 = "", chip2 = "", chip3 = "", expansion = ""}) do
        widget.setItemSlotItem("itemSlot_" .. chipName, nil)
      end

      if self.chips then
        for chipName, itemDescriptor in pairs(self.chips) do
          widget.setItemSlotItem("itemSlot_" .. chipName, itemDescriptor)
        end
      end

      for partType,_ in pairs({rightArm = "", leftArm = "", body = "", booster = "", legs = ""}) do
        widget.setItemSlotItem("itemSlot_" .. partType, nil)
      end

      if self.itemSet then
        for partType, itemDescriptor in pairs(self.itemSet) do
          widget.setItemSlotItem("itemSlot_" .. partType, itemDescriptor)
        end
      end

      updatePreview()
    end
    self.loadoutsMessage = nil
    self.loadoutsChanged = nil
  end
end

function changeLoadout()
  local selected = widget.getSelectedOption("radioLoadouts")
  if not selected then return end

  world.sendEntityMessage(player.id(), "setCurrentLoadout", selected)

  self.loadoutsChanged = true
end

function updatePreview()
  if self.disabled then return end

  -- assemble vehicle and animation config
  local params = self.partManager:buildVehicleParameters(self.itemSet, self.primaryColorIndex, self.secondaryColorIndex)
  params = MechPartManager.calculateBonuses(params, self.chips)
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
    params = MechPartManager.calculateTotalMass(params, self.chips)

    local healthMax = params.parts.body.healthMax + params.parts.body.healthBonus
    local speedPenaltyPercent = math.floor((params.parts.body.speedNerf or 0) * 100)
    local energyMax = params.parts.body.energyMax
    local energyDrain = params.parts.body.energyDrain + params.parts.leftArm.energyDrain + params.parts.rightArm.energyDrain

    local chips = self.chips or {}
    for _,chip in pairs(chips) do
      if chip.name == "mechchiprefueler" then
        energyDrain = energyDrain * 0.75
      end
    end

	  --energyDrain = energyDrain * 0.6
    energyDrain = energyDrain + params.parts.body.energyPenalty
    local mass = params.parts.body.totalMass

    widget.setVisible("lblHealth", true)
    widget.setVisible("lblEnergy", true)
    widget.setVisible("lblDrain", true)
    widget.setVisible("lblHealthBonus", true)
    widget.setVisible("lblSpeedPenalty", true)
    widget.setVisible("lblEnergyPenalty", true)

    widget.setText("lblHealth", string.format("Health: %d", healthMax))
    widget.setText("lblEnergy", string.format("Fuel: %d", energyMax))
    widget.setText("lblDrain", string.format("Fuel usage: %.02f F/s", energyDrain))
    widget.setText("lblMass", string.format("Mech mass: %.01f t", mass))
    widget.setText("lblHealthBonus", string.format("Mass health bonus: %d", params.parts.body.healthBonus))
    widget.setText("lblSpeedPenalty", "Mass speed penalty: -" .. speedPenaltyPercent .. "%")
    widget.setText("lblEnergyPenalty", string.format("Mass drain penalty: %.02f F/s", params.parts.body.energyPenalty))

  else
    widget.setVisible("lblHealth", false)
    widget.setVisible("lblEnergy", false)
    widget.setVisible("lblDrain", false)
    widget.setVisible("lblMass", false)
    widget.setVisible("lblHealthBonus", false)
    widget.setVisible("lblSpeedPenalty", false)
    widget.setVisible("lblEnergyPenalty", false)
  end
end
