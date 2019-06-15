function init()
  self.drainArea = object.spaces()
  object.setInteractive(true)
  
  setDirection(storage.doorDirection or object.direction())

  self.sensorConfig = config.getParameter("sensorConfig")
  
  self.openDuration = 2
  self.timer = 0
  self.wiredOpen = false

  if storage.locked == nil then
    storage.locked = config.getParameter("locked", false)
  end

  if storage.state == nil then
    if config.getParameter("defaultState") == "open" then
      openDoor()
    else
      closeDoor()
    end
  else
    animator.setAnimationState("doorState", storage.state and "open" or "closed")
  end

  updateCollisionAndWires()
  updateInteractive()
  updateLight()

  message.setHandler("openDoor", function() openDoor() end)
  message.setHandler("closeDoor", function() closeDoor() end)
  message.setHandler("lockDoor", function() lockDoor() end)
end

function update(dt)
  if self.timer < 0 then
    if not self.wiredOpen then
      closeDoor()
    end
  else
    self.timer = self.timer - dt
  end
  
end

function onNodeConnectionChange(args)
  updateInteractive()
  updateCollisionAndWires()
  if object.isInputNodeConnected(0) then
    onInputNodeChange({ level = object.getInputNodeLevel(0) })
  end
end

function onInputNodeChange(args)
  if args.level then
    self.wiredOpen = true
    self.timer = self.openDuration
    openDoor(storage.doorDirection)
  else
    self.wiredOpen = false
    closeDoor()
  end
end

function onInteraction(args)
  if storage.locked then
    animator.playSound("locked")
  else
    if not storage.state then
      self.timer = self.openDuration
      openDoor(args.source[1])
    else
      closeDoor()
    end
  end
end

function updateLight()
  if not storage.state then
    object.setLightColor(config.getParameter("closedLight", {0,0,0,0}))
  else
    object.setLightColor(config.getParameter("openLight", {0,0,0,0}))
  end
end

function updateInteractive()
  object.setInteractive(config.getParameter("interactive", true) and not self.sensorConfig and not object.isInputNodeConnected(0) and not storage.locked)
end

function updateCollisionAndWires()
  setupMaterialSpaces()
  object.setMaterialSpaces(storage.state and self.openMaterialSpaces or self.closedMaterialSpaces)
  object.setAllOutputNodes(storage.state)
end

function setupMaterialSpaces()
  self.closedMaterialSpaces = config.getParameter("closedMaterialSpaces")
  if not self.closedMaterialSpaces then
    self.closedMaterialSpaces = {}
    local metamaterial = "metamaterial:door"
    if object.isInputNodeConnected(0) then
      metamaterial = "metamaterial:lockedDoor"
    end
    for i, space in ipairs(object.spaces()) do
      table.insert(self.closedMaterialSpaces, {space, metamaterial})
    end
  end
  self.openMaterialSpaces = config.getParameter("openMaterialSpaces", {})
end

function setDirection(direction)
  storage.doorDirection = direction
  animator.setGlobalTag("doorDirection", direction < 0 and "Left" or "Right")
end

function hasCapability(capability)
  if capability == 'lockedDoor' then
    return storage.locked
  elseif object.isInputNodeConnected(0) or storage.locked or self.sensorConfig then
    return false
  elseif capability == 'door' then
    return true
  elseif capability == 'closedDoor' then
    return not storage.state
  elseif capability == 'openDoor' then
    return storage.state
  else
    return false
  end
end

function doorOccupiesSpace(position)
  local relative = {position[1] - object.position()[1], position[2] - object.position()[2]}
  for _, space in ipairs(object.spaces()) do
    if math.floor(relative[1]) == space[1] and math.floor(relative[2]) == space[2] then
      return true
    end
  end
  return false
end

function lockDoor()
  if not storage.locked then
    storage.locked = true
    updateInteractive()
    if storage.state then
      -- close door before locking
      storage.state = false
      animator.playSound("close")
      animator.setAnimationState("doorState", "locking")
      updateCollisionAndWires()
    else
      animator.setAnimationState("doorState", "locked")
    end
    return true
  end
end

function unlockDoor()
  if storage.locked then
    storage.locked = false
    updateInteractive()
    animator.setAnimationState("doorState", "closed")
    return true
  end
end

function closeDoor()
  if storage.state ~= false then
    storage.state = false
    updateInteractive()
    animator.playSound("close")
    animator.setAnimationState("doorState", "closing")
    updateCollisionAndWires()
    updateLight()
  end
end

function openDoor(direction)
  if not storage.state then
    storage.state = true
    storage.locked = false -- make sure we don't get out of sync when wired
    updateInteractive()
    setDirection((direction == nil or direction * object.direction() < 0) and -1 or 1)
    animator.playSound("open")
    animator.setAnimationState("doorState", "open")
    updateCollisionAndWires()
    updateLight()
  end
end