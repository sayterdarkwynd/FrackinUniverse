function init()
  object.setInteractive(config.getParameter("interactive", true))

  self.hasNotGate = config.getParameter("hasNotGate")
  if self.hasNotGate then
    self.notGateNode = config.getParameter("notGateNode")
    if self.notGateNode == nil then
      self.hasNotGate = false
    end
  else
    self.hasNotGate = false
  end

  self.hasStateToggle = config.getParameter("hasStateToggle")
  if self.hasStateToggle then
    self.stateToggleNode = config.getParameter("stateToggleNode")
    if self.stateToggleNode == nil then
      self.hasStateToggle = false
    end
  else
    self.hasStateToggle = false
  end

  self.hasPersistentSwitchFunctionality = config.getParameter("hasPersistentSwitchFunctionality")
  if self.hasPersistentSwitchFunctionality then
    self.persistentSwitchOnNode = config.getParameter("persistentSwitchOnNode")
    self.persistentSwitchOffNode = config.getParameter("persistentSwitchOffNode")
    if self.persistentSwitchOnNode == nil or self.persistentSwitchOffNode == nil then
      self.hasPersistentSwitchFunctionality = false
    end
  else
    self.hasPersistentSwitchFunctionality = false
  end

  self.hasInteractiveToggle = config.getParameter("hasInteractiveToggle")
  if self.hasInteractiveToggle then
    self.interactiveToggleNode = config.getParameter("interactiveToggleNode")
    if self.interactiveToggleNode == nil then
      self.hasInteractiveToggle = false
    end
  else
    self.hasInteractiveToggle = false
  end

  self.hasLatch = config.getParameter("hasLatch")
  if self.hasLatch then
    self.latchNode = config.getParameter("latchNode")
    if self.latchNode == nil then
      self.hasLatch = false
    end
  else
    self.hasLatch = false
  end

  if storage.state == nil then
    output(config.getParameter("defaultSwitchState", false))
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
    animator.setAnimationState("switchState", "on")
    if not (config.getParameter("alwaysLit")) then object.setLightColor(config.getParameter("lightColor", {0, 0, 0, 0})) end
    animator.playSound("on");
    object.setAllOutputNodes(true)
    if self.hasNotGate then
      object.setOutputNodeLevel(self.notGateNode, false)
    end
  else
    animator.setAnimationState("switchState", "off")
    if not (config.getParameter("alwaysLit")) then object.setLightColor({0, 0, 0, 0}) end
    animator.playSound("off");
    object.setAllOutputNodes(false)
    if self.hasNotGate then
      object.setOutputNodeLevel(self.notGateNode, true)
    end
  end
end

function update(dt)
  if not self.hasInteractiveToggle or not object.isInputNodeConnected(self.interactiveToggleNode) or object.getInputNodeLevel(self.interactiveToggleNode) then
    object.setInteractive(config.getParameter("interactive", true))
  else
    object.setInteractive(false)
  end
  if not self.hasLatch or not object.isInputNodeConnected(self.latchNode) or object.getInputNodeLevel(self.latchNode) then
    if not self.hasPersistentSwitchFunctionality or object.getInputNodeLevel(self.persistentSwitchOnNode) == object.getInputNodeLevel(self.persistentSwitchOffNode) then
      if self.hasStateToggle and object.getInputNodeLevel(self.stateToggleNode) and not storage.triggered then
        storage.triggered = true
        output(not storage.state)
      elseif self.hasStateToggle and storage.triggered and not object.getInputNodeLevel(self.stateToggleNode) then
        storage.triggered = false
      end
    else
      object.setInteractive(false)
      if object.getInputNodeLevel(self.persistentSwitchOnNode) and not object.getInputNodeLevel(self.persistentSwitchOffNode) and not storage.state then
        output(true)
      elseif object.getInputNodeLevel(self.persistentSwitchOffNode) and not object.getInputNodeLevel(self.persistentSwitchOnNode) and storage.state then
        output(false)
      end
    end
  end
end