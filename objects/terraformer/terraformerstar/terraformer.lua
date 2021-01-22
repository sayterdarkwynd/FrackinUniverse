require "/scripts/vec2.lua"

function init()
  self.minPregenerateTime = config.getParameter("minPregenerateTime", 5)
  self.basePregenerateTime = config.getParameter("basePregenerateTime", 10)
  self.pregenerateTimePerTile = config.getParameter("pregenerateTimePerTile", 0.1)

  self.planetTypeChangeThreshold = config.getParameter("planetTypeChangeThreshold")
  self.terraformInterferenceBuffer = config.getParameter("terraformInterferenceBuffer", 50)

  self.biome = config.getParameter("terraformBiome")
  self.planetType = config.getParameter("terraformPlanetType")

  self.guiConfig = root.assetJson("/interface/scripted/terraformer/terraformergui.config")
  self.guiConfig.gui.windowtitle.title = "  " .. config.getParameter("shortdescription")
  self.guiConfig.planetType = self.planetType

  local terraformOffset = config.getParameter("terraformOffset", {0, 0})
  self.terraformPosition = vec2.add(entity.position(), terraformOffset)

  storage.uuid = storage.uuid or sb.makeUuid()
  storage.size = storage.size or 0
  storage.targetSize = storage.targetSize or storage.size

  if storage.activated then
    register()
  end

  updateInteractive()
  updateAnimation()

  message.setHandler("getStatus", function()
      return {
        active = not not (storage.addTimer or storage.expandTimer),
        currentSize = storage.size or 0
      }
    end)

  message.setHandler("activate", function(_, _, targetSize)
      local success, errorCode = activate(targetSize)
      return {
        success = success,
        errorCode = errorCode,
        expandAmount = math.max(0, targetSize - storage.size)
      }
    end)

  message.setHandler("confirmActivation", function()
      storage.activationConfirmed = true
    end)

  message.setHandler("cancelActivation", function()
      storage.addTimer = nil
      storage.expandTimer = nil
      storage.targetSize = storage.size
      updateAnimation()
      updateInteractive()
    end)
end

function onInteraction(args)
  return {"ScriptPane", self.guiConfig}
end

function update(dt)
  if storage.addTimer then
    storage.addTimer = storage.addTimer + dt

    if not self.pregenerationFinished then
      self.pregenerationFinished = world.pregenerateAddBiome(self.terraformPosition, storage.targetSize)
      -- if self.pregenerationFinished then sb.logInfo("pregeneration to add biome finished after %s seconds", storage.addTimer) end
    end

    if storage.addTimer >= self.minPregenerateTime and self.pregenerationFinished or (storage.addTimer >= storage.pregenerateTimeLimit) then
      world.addBiomeRegion(self.terraformPosition, self.biome, "largeClumps", storage.targetSize)

      storage.size = storage.targetSize

      -- sb.logInfo("added biome %s at %s with size %s after %s seconds of pregeneration", self.biome, self.terraformPosition, storage.targetSize, storage.addTimer)

      storage.addTimer = nil

      animator.playSound("deactivate")
      updatePlanetType()
      updateInteractive()
      updateAnimation()
    end
  elseif storage.expandTimer then
    storage.expandTimer = storage.expandTimer + dt

    if not self.pregenerationFinished then
      self.pregenerationFinished = world.pregenerateExpandBiome(self.terraformPosition, storage.targetSize)
      -- if self.pregenerationFinished then sb.logInfo("pregeneration to expand biome finished after %s seconds", storage.expandTimer) end
    end

    if storage.expandTimer >= self.minPregenerateTime and self.pregenerationFinished or (storage.expandTimer >= storage.pregenerateTimeLimit) then
      world.expandBiomeRegion(self.terraformPosition, storage.targetSize)

      storage.size = storage.targetSize

      -- sb.logInfo("expanded biome at %s to size %s after %s seconds of pregeneration", self.terraformPosition, storage.targetSize, storage.expandTimer)

      storage.expandTimer = nil

      animator.playSound("deactivate")
      updatePlanetType()
      updateInteractive()
      updateAnimation()
    end
  end
end

function die()
  deregister()
end

function updateInteractive()
  object.setInteractive(not (storage.addTimer or storage.expandTimer))
end

function updateAnimation()
  if storage.activated then
    if storage.addTimer or storage.expandTimer then
      animator.setAnimationState("baseState", "active")
      animator.setAnimationState("beamState", "active")
    else
      animator.setAnimationState("baseState", "idle")
      animator.setAnimationState("beamState", "idle")
    end
  else
    animator.setAnimationState("baseState", "inactive")
    animator.setAnimationState("beamState", "inactive")
  end
end

function canActivate(newRegionSize)
  if not world.inSurfaceLayer(self.terraformPosition) then
    return false, "needSurface"
  end

  local checkRadius = (newRegionSize / 2) + self.terraformInterferenceBuffer
  local activeTerraformers = world.getProperty("activeTerraformers") or {}
  for k, pos in pairs(activeTerraformers) do
    if k ~= storage.uuid and world.magnitude(self.terraformPosition, pos) < checkRadius then
      return false, "tooClose"
      -- return false, string.format("%s too close to another active terraformer %s at %d, %d", storage.uuid, k, pos[1], pos[2])
    end
  end

  return true, ""
end

function activate(targetSize)
  if storage.size >= world.size()[1] then
    return false, "worldComplete"
  end

  if targetSize <= storage.size then
    return false, "noExpansion"
  end

  if storage.addTimer or storage.expandTimer then
    return false, "alreadyActive"
  end

  if storage.activated then
    local success, reason = canActivate(targetSize)
    if success then
      triggerExpand(targetSize)
      updateInteractive()
    else
      -- return { "ShowPopup", { title = "Activation Failed!", message = string.format("^red;Terraformer failed to activate: %s.", reason), sound = "" } }
    end
    return success, reason or ""
  else
    local success, reason = canActivate(targetSize)
    if success then
      storage.activated = true
      register()
      triggerAdd(targetSize)
    else
      -- return { "ShowPopup", { title = "Activation Failed!", message = string.format("^red;Terraformer failed to activate: %s.", reason), sound = "" } }
    end
    return success, reason or ""
  end
end

function triggerAdd(targetSize)
  storage.targetSize = targetSize
  storage.activationConfirmed = false
  storage.addTimer = 0
  storage.pregenerateTimeLimit = pregenerateTimeLimit(targetSize)
  self.pregenerationFinished = false
  animator.playSound("activate")
  animator.setAnimationState("baseState", "activate")
  animator.setAnimationState("beamState", "activate")
end

function triggerExpand(targetSize)
  storage.targetSize = targetSize
  storage.activationConfirmed = false
  storage.expandTimer = 0
  storage.pregenerateTimeLimit = pregenerateTimeLimit(targetSize)
  self.pregenerationFinished = false
  animator.playSound("activate")
  updateAnimation()
end

function pregenerateTimeLimit(targetSize)
  return self.basePregenerateTime + (targetSize - (storage.size or 0)) * self.pregenerateTimePerTile
end

function updatePlanetType()
  if not storage.planetTypeChanged then
    local sizeRatio = storage.size / world.size()[1]
    if sizeRatio >= self.planetTypeChangeThreshold then
      storage.planetTypeChanged = true
      world.setPlanetType(self.planetType, self.biome)
      world.setLayerEnvironmentBiome(self.terraformPosition)
    end
  end
end

function register()
  local activeTerraformers = world.getProperty("activeTerraformers") or {}

  activeTerraformers[storage.uuid] = self.terraformPosition

  world.setProperty("activeTerraformers", activeTerraformers)
end

function deregister()
  local activeTerraformers = world.getProperty("activeTerraformers") or {}

  activeTerraformers[storage.uuid] = nil

  world.setProperty("activeTerraformers", activeTerraformers)
end
