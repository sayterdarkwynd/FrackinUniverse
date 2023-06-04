function init()
  object.setInteractive(config.getParameter("interactive", false))

  self.stateCount = config.getParameter("stateCount")
  self.incrementingNode = config.getParameter("incrementingNode", 1)
  self.decrementingNode = config.getParameter("decrementingNode", 0)

  self.hasLatch = config.getParameter("hasLatch", false)
  if self.hasLatch then
    self.latchNode = config.getParameter("latchNode")
    if self.latchNode == nil then
      self.hasLatch = false
    end
  else
    self.hasLatch = false
  end

  if storage.state == nil then
    output(config.getParameter("defaultSwitchState", 0))
  else
    output(storage.state)
  end

  if storage.triggeredUp == nil then
    storage.triggeredUp = false
  end
  if storage.triggeredDown == nil then
    storage.triggeredDown = false
  end

  self.hasStateInputs = config.getParameter("hasStateInputs", false)
  if self.hasStateInputs then
    storage.triggeredState = { false, false, false, false, false, false, false, false, false, false, false, false, false, false, false, false }
  end
end

function state()
  return storage.state
end

function onInteraction(args)
  output(storage.state + 1)
end

function onNpcPlay(npcId)
  onInteraction()
end

function output(state)
  if state >= self.stateCount then
    state = 0
  elseif state < 0 then
    state = self.stateCount-1
  end

  storage.state = state
  animator.setAnimationState("switchState", state)
  object.setAllOutputNodes(false)
  object.setOutputNodeLevel(state, true)
end

function update(dt)
  if not self.hasLatch or not object.isInputNodeConnected(self.latchNode) or object.getInputNodeLevel(self.latchNode) then
    if object.getInputNodeLevel(self.incrementingNode) then
      if not storage.triggeredUp then
        storage.triggeredUp = true
        output(storage.state + 1)
      end
    elseif storage.triggeredUp then
      storage.triggeredUp = false
    end
    if object.getInputNodeLevel(self.decrementingNode) then
      if not storage.triggeredDown then
        storage.triggeredDown = true
        output(storage.state - 1)
      end
    elseif storage.triggeredDown then
      storage.triggeredDown = false
    end

    if self.hasStateInputs then
      i = 0
      while i < self.stateCount do
        if object.getInputNodeLevel(i) then
          if not storage.triggeredState[i] then
            storage.triggeredState[i] = true
            output(i)
          end
        elseif storage.triggeredState[i] then
          storage.triggeredState[i] = false
        end

        i = i + 1
      end
    end
  end
end