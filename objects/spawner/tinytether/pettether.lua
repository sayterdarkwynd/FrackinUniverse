require "/scripts/companions/petspawner.lua"

function init()
  petSpawner:init()

  self.firstUpdate = true
end

function finishInit()
  local uniqueId = entity.uniqueId()
  if not uniqueId then
    uniqueId = sb.makeUuid()
    world.setUniqueId(entity.id(), uniqueId)
  end
  petSpawner.tetherUniqueId = uniqueId
  petSpawner.ownerUuid = config.getParameter("owner")
  petSpawner.levelOverride = math.max(world.threatLevel(), world.getProperty("ship.level") or 0)
end

function uninit()
  for uuid, pod in pairs(petSpawner.pods) do
    -- Tether is unloading or being destroyed, return all pets
    pod:recall()
  end
end

function updatePodsFromItems()
  local pods = {}

  local items = world.containerItems(entity.id())
  for _,item in pairs(items) do
    if item.parameters and item.parameters.podUuid then
      pods[item.parameters.podUuid] = item
    end
  end

  local newPods = copy(pods)
  local removedPods = {}

  for uuid, pod in pairs(petSpawner.pods) do
    if pods[uuid] then
      newPods[uuid] = nil
    else
      removedPods[uuid] = true
    end
  end

  for uuid,_ in pairs(removedPods) do
    petSpawner.pods[uuid]:recall()
    petSpawner.pods[uuid] = nil
  end

  for uuid, item in pairs(newPods) do
    petSpawner.pods[uuid] = Pod.new(uuid, item.parameters.currentPets or item.parameters.pets)
    petSpawner.pods[uuid]:release()
  end

  for uuid, item in pairs(pods) do
    petSpawner:setPodCollar(uuid, item.parameters.currentCollar)
  end

  if not isEmpty(petSpawner.pods) then
    animator.setAnimationState("tetherState", "on")
  else
    animator.setAnimationState("tetherState", "off")
  end
end

function updateItemsFromPods()
  local podIndices = {}

  for i = 0, world.containerSize(entity.id())-1 do
    local item = world.containerItemAt(entity.id(), i)
    if item and item.parameters and item.parameters.podUuid then
      podIndices[item.parameters.podUuid] = i
    end
  end

  for uuid, index in pairs(podIndices) do
    local item = world.containerItemAt(entity.id(), index)
    item.parameters.currentPets = petSpawner.pods[uuid]:store().pets
    item.parameters.podItemHasPriority = true
    world.containerSwapItemsNoCombine(entity.id(), item, index)
  end
end

function update(dt)
  if self.firstUpdate then
    self.firstUpdate = false
    finishInit()
  end

  promises:update()

  updatePodsFromItems()

  for uuid, pod in pairs(petSpawner.pods) do
    pod:update(dt)
  end

  if petSpawner:isDirty() then
    updateItemsFromPods()
    petSpawner:clearDirty()
  end
end
