require "/scripts/util.lua"

MechPartManager = {}

function MechPartManager:new()
  local newPartManager = {}

  -- all possible types of parts
  newPartManager.partTypes = {
    "leftArm",
    "rightArm",
    "booster",
    "body",
    "legs",
    "horn"
  }

  -- parts required for a mech to launch
  newPartManager.requiredParts = {
    "leftArm",
    "rightArm",
    "body",
    "booster",
    "legs"
  }

  -- maps the stat levels in part configurations to functions which
  -- determine the numerical stats applied to each part
  newPartManager.partStatMap = {
    body = {
      energy = {
        energyMax = "mechBodyEnergyMax",
        energyDrain = "mechBodyEnergyDrain"
      },
      protection = {
        protection = "mechBodyProtection"
      }
    },
    booster = {
      speed = {
        airControlSpeed = "mechBoosterAirControlSpeed",
        flightControlSpeed = "mechBoosterFlightControlSpeed"
      },
      control = {
        airControlForce = "mechBoosterAirControlForce",
        flightControlForce = "mechBoosterFlightControlForce"
      }
    },
    legs = {
      speed = {
        groundSpeed = "mechLegsGroundSpeed",
        groundControlForce = "mechLegsGroundControlForce"
      },
      jump = {
        jumpVelocity = "mechLegsJumpVelocity",
        jumpAirControlSpeed = "mechLegsJumpAirControlSpeed",
        jumpAirControlForce = "mechLegsJumpAirControlForce",
        jumpBoostTime = "mechLegsJumpBoostTime"
      }
    },
    leftArm = {
      power = {
	--mechPower = "mechPowerModifier"       
      },
      energy = {
        energyDrain = "mechArmEnergyDrain"
      }
    },
    rightArm = {
      power = {
	--mechPower = "mechPowerModifier"       
      },
      energy = {
        energyDrain = "mechArmEnergyDrain"
      }
    }
  }

  -- load part configurations
  newPartManager.partTypeConfigs = {
    arm = root.assetJson("/vehicles/modularmech/mechparts_arm.config"),
    body = root.assetJson("/vehicles/modularmech/mechparts_body.config"),
    booster = root.assetJson("/vehicles/modularmech/mechparts_booster.config"),
    legs = root.assetJson("/vehicles/modularmech/mechparts_legs.config"),
    horn = root.assetJson("/vehicles/modularmech/mechparts_horn.config")
  }

  newPartManager.paletteConfig = root.assetJson("/vehicles/modularmech/mechpalettes.config")

  setmetatable(newPartManager, extend(self))
  return newPartManager
end

function MechPartManager:partConfig(partType, itemDescriptor)
  local typeKey = (partType == "leftArm" or partType == "rightArm") and "arm" or partType
  local itemConfig = root.itemConfig(itemDescriptor)
  if itemConfig then
    local mechPartConfig = itemConfig.parameters.mechPart or itemConfig.config.mechPart
    if type(mechPartConfig) == "table" and #mechPartConfig == 2 then
      if mechPartConfig[1] == typeKey and self.partTypeConfigs[typeKey] then
        return copy(self.partTypeConfigs[typeKey][mechPartConfig[2]])
      end
    end
  end
end

function MechPartManager:validateItemSet(itemSet)
  if type(itemSet) ~= "table" then return {} end

  local validSet = {}
  for _, partType in ipairs(self.partTypes) do
    if itemSet[partType] and self:partConfig(partType, itemSet[partType]) then
      validSet[partType] = itemSet[partType]
    -- else
    --   sb.logError("Item %s not valid for part type %s", itemSet[partType] or "nil", partType)
    end
  end
  return validSet
end

function MechPartManager:itemSetComplete(itemSet)
  for _, partName in ipairs(self.requiredParts) do
    if not itemSet[partName] then return false end
  end
  return true
end

function MechPartManager:missingParts(itemSet)
  local res = {}
  for _, partName in ipairs(self.requiredParts) do
    if not itemSet[partName] then
      table.insert(res, partName)
    end
  end
  return res
end

function MechPartManager:buildVehicleParameters(itemSet, primaryColorIndex, secondaryColorIndex)
  local params = {
    parts = {},
    partDirectives = {},
    partImages = {},
    animationCustom = {},
    damageSources = {},
    loungePositions = {},
    physicsForces = {},
    physicsCollisions = {}
  }
  
  --local mechStatSum = 0
  --local mechChestBonus = 0
  --local mechBoosterBonus = 0
  --local mechLegsBonus = 0
  
  for partType, itemDescriptor in pairs(itemSet) do
    local thisPartConfig = self:partConfig(partType, itemDescriptor)
    if partType == "leftArm" or partType == "rightArm" then
      thisPartConfig = util.replaceTag(thisPartConfig, "armName", partType)
    end

    if partType ~= "horn" then
      if self.partStatMap[partType] and thisPartConfig.stats then
        -- ***** FU additions
        -- load the arms stat table
        thisPartConfig.partParameters.stats = copy(thisPartConfig.stats)
        
	-- look for stats
        --for nam, sta in pairs(thisPartConfig.partParameters.stats) do
        --  mechStatSum = mechStatSum + sta
        --end  

        -- *****        
        for stat, fMap in pairs(self.partStatMap[partType]) do
          for param, fName in pairs(fMap) do
            thisPartConfig.partParameters[param] = root.evalFunction(fName, thisPartConfig.stats[stat])
          end
        end
      end

      params.parts[partType] = thisPartConfig.partParameters

      primaryColorIndex = self:validateColorIndex(primaryColorIndex)
      secondaryColorIndex = self:validateColorIndex(secondaryColorIndex)
      params.partDirectives[partType] = self:buildSwapDirectives(thisPartConfig, primaryColorIndex, secondaryColorIndex)

      params.partImages = util.mergeTable(params.partImages, thisPartConfig.partImages or {})
      params.damageSources = util.mergeTable(params.damageSources, thisPartConfig.damageSources or {})
      params.loungePositions = util.mergeTable(params.loungePositions, thisPartConfig.loungePositions or {})
      params.physicsForces = util.mergeTable(params.physicsForces, thisPartConfig.physicsForces or {})
      params.physicsCollisions = util.mergeTable(params.physicsCollisions, thisPartConfig.physicsCollisions or {})
    end

    params.animationCustom = util.mergeTable(params.animationCustom, thisPartConfig.animationCustom or {})
  end
  
  return params
end

function MechPartManager:validateColorIndex(colorIndex)
  if type(colorIndex) ~= "number" then return 0 end

  if colorIndex > #self.paletteConfig.swapSets or colorIndex < 0 then
    colorIndex = colorIndex % (#self.paletteConfig.swapSets + 1)
  end
  return colorIndex
end

function MechPartManager:buildSwapDirectives(partConfig, primaryIndex, secondaryIndex)
  local result = ""
  local primaryColors = primaryIndex == 0 and partConfig.defaultPrimaryColors or self.paletteConfig.swapSets[primaryIndex]
  for i, fromColor in ipairs(self.paletteConfig.primaryMagicColors) do
    result = string.format("%s?replace=%s=%s", result, fromColor, primaryColors[i])
  end
  local secondaryColors = secondaryIndex == 0 and partConfig.defaultSecondaryColors or self.paletteConfig.swapSets[secondaryIndex]
  for i, fromColor in ipairs(self.paletteConfig.secondaryMagicColors) do
    result = string.format("%s?replace=%s=%s", result, fromColor, secondaryColors[i])
  end
  return result
end

