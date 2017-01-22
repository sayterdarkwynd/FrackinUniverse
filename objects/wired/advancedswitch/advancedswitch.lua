function init()
  entity.setInteractive(entity.configParameter("interactive", true))

  self.hasNotGate = entity.configParameter("hasNotGate")
  if self.hasNotGate then
    self.notGateNode = entity.configParameter("notGateNode")
    if self.notGateNode == nil then
      self.hasNotGate = false
    end
  else
    self.hasNotGate = false
  end

  self.hasStateToggle = entity.configParameter("hasStateToggle")
  if self.hasStateToggle then
    self.stateToggleNode = entity.configParameter("stateToggleNode")
    if self.stateToggleNode == nil then
      self.hasStateToggle = false
    end
  else
    self.hasStateToggle = false
  end

  self.hasPersistentSwitchFunctionality = entity.configParameter("hasPersistentSwitchFunctionality")
  if self.hasPersistentSwitchFunctionality then
    self.persistentSwitchOnNode = entity.configParameter("persistentSwitchOnNode")
    self.persistentSwitchOffNode = entity.configParameter("persistentSwitchOffNode")
    if self.persistentSwitchOnNode == nil or self.persistentSwitchOffNode == nil then
      self.hasPersistentSwitchFunctionality = false
    end
  else
    self.hasPersistentSwitchFunctionality = false
  end

  self.hasInteractiveToggle = entity.configParameter("hasInteractiveToggle")
  if self.hasInteractiveToggle then
    self.interactiveToggleNode = entity.configParameter("interactiveToggleNode")
    if self.interactiveToggleNode == nil then
      self.hasInteractiveToggle = false
    end
  else
    self.hasInteractiveToggle = false
  end

  self.hasLatch = entity.configParameter("hasLatch")
  if self.hasLatch then
    self.latchNode = entity.configParameter("latchNode")
    if self.latchNode == nil then
      self.hasLatch = false
    end
  else
    self.hasLatch = false
  end

  if storage.state == nil then
    output(entity.configParameter("defaultSwitchState", false))
  else
    output(storage.state)
  end

  if storage.triggered == nil then
    storage.triggered = false
  end
end

function state()
  return storage.state
end

function onInteraction(args)
  output(not storage.state)
end

function onNpcPlay(npcId)
  onInteraction()
end

function output(state)
  storage.state = state
  if state then
    entity.setAnimationState("switchState", "on")
    if not (entity.configParameter("alwaysLit")) then entity.setLightColor(entity.configParameter("lightColor", {0, 0, 0, 0})) end
    entity.playSound("on");
    entity.setAlloutputNodes(true)
    if self.hasNotGate then
      entity.setOutboundNodeLevel(self.notGateNode, false)
    end
  else
    entity.setAnimationState("switchState", "off")
    if not (entity.configParameter("alwaysLit")) then entity.setLightColor({0, 0, 0, 0}) end
    entity.playSound("off");
    entity.setAlloutputNodes(false)
    if self.hasNotGate then
      entity.setOutboundNodeLevel(self.notGateNode, true)
    end
  end
end

function update(dt)
  if not self.hasInteractiveToggle or not entity.isInboundNodeConnected(self.interactiveToggleNode) or entity.getInboundNodeLevel(self.interactiveToggleNode) then
    entity.setInteractive(entity.configParameter("interactive", true))
  else
    entity.setInteractive(false)
  end
  if not self.hasLatch or not entity.isInboundNodeConnected(self.latchNode) or entity.getInboundNodeLevel(self.latchNode) then
    if not self.hasPersistentSwitchFunctionality or entity.getInboundNodeLevel(self.persistentSwitchOnNode) == entity.getInboundNodeLevel(self.persistentSwitchOffNode) then
      if self.hasStateToggle and entity.getInboundNodeLevel(self.stateToggleNode) and not storage.triggered then
        storage.triggered = true
        output(not storage.state)
      elseif self.hasStateToggle and storage.triggered and not entity.getInboundNodeLevel(self.stateToggleNode) then
        storage.triggered = false
      end
    else
      entity.setInteractive(false)
      if entity.getInboundNodeLevel(self.persistentSwitchOnNode) and not entity.getInboundNodeLevel(self.persistentSwitchOffNode) and not storage.state then
        output(true)
      elseif entity.getInboundNodeLevel(self.persistentSwitchOffNode) and not entity.getInboundNodeLevel(self.persistentSwitchOnNode) and storage.state then
        output(false)
      end
    end
  end
end