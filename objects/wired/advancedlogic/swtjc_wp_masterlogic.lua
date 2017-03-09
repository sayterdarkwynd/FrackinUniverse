function init()
  object.setInteractive(false)
  storage.state = 0
  animator.setAnimationState("switchState", storage.state)

  self.andGateNode = config.getParameter("andGateNode")
  self.orGateNode = config.getParameter("orGateNode")
  self.xorGateNode = config.getParameter("xorGateNode")
  self.nandGateNode = config.getParameter("nandGateNode")
  self.norGateNode = config.getParameter("norGateNode")
  self.nxorGateNode = config.getParameter("nxorGateNode")

  if storage.andState == nil then
    outputAnd(false)
  else
    object.setOutputNodeLevel(self.andGateNode, storage.andState)
    object.setOutputNodeLevel(self.nandGateNode, not storage.andState)
  end
  if storage.orState == nil then
    outputOr(false)
  else
    object.setOutputNodeLevel(self.orGateNode, storage.orState)
    object.setOutputNodeLevel(self.norGateNode, not storage.orState)
  end
  if storage.xorState == nil then
    outputXor(false)
  else
    object.setOutputNodeLevel(self.xorGateNode, storage.xorState)
    object.setOutputNodeLevel(self.nxorGateNode, not storage.xorState)
  end

  self.gates = config.getParameter("gates")
  self.andTruthtable = config.getParameter("andTruthtable")
  self.orTruthtable = config.getParameter("orTruthtable")
  self.xorTruthtable = config.getParameter("xorTruthtable")

  self.hasLatch = config.getParameter("hasLatch")
  if self.hasLatch then
    self.latchNode = config.getParameter("latchNode")
    if self.latchNode == nil then
      self.hasLatch = false
    end
  else
    self.hasLatch = false
  end

  if self.gates >= 1 then
    self.gateNode1 = config.getParameter("gateNode1")
    if self.gates >= 2 then
      self.gateNode2 = config.getParameter("gateNode2")
      if self.gates >= 3 then
        self.gateNode3 = config.getParameter("gateNode3")
        if self.gates >= 4 then
          self.gateNode4 = config.getParameter("gateNode4")
          self.gates = 4
        end
      end
    end
  end
end

function outputAnd(state)
  if storage.andState ~= state then
    storage.andState = state
    object.setOutputNodeLevel(self.andGateNode, state)
    object.setOutputNodeLevel(self.nandGateNode, not state)
  end
end

function outputOr(state)
  if storage.orState ~= state then
    storage.orState = state
    object.setOutputNodeLevel(self.orGateNode, state)
    object.setOutputNodeLevel(self.norGateNode, not state)
  end
end

function outputXor(state)
  if storage.xorState ~= state then
    storage.xorState = state
    object.setOutputNodeLevel(self.xorGateNode, state)
    object.setOutputNodeLevel(self.nxorGateNode, not state)
  end
end

function toIndex(truth)
  if truth then
    return 2
  else
    return 1
  end
end

function update(dt)
  if not self.hasLatch or not object.isInputNodeConnected(self.latchNode) or object.getInputNodeLevel(self.latchNode) then
    if self.gates == 1 then
      outputAnd(self.andTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))])
      outputOr(self.orTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))])
      outputXor(self.xorTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))])
    elseif self.gates == 2 then
      outputAnd(self.andTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))])
      outputOr(self.orTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))])
      outputXor(self.xorTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))])
    elseif self.gates == 3 then
      outputAnd(self.andTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))][toIndex(object.getInputNodeLevel(self.gateNode3))])
      outputOr(self.orTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))][toIndex(object.getInputNodeLevel(self.gateNode3))])
      outputXor(self.xorTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))][toIndex(object.getInputNodeLevel(self.gateNode3))])
    elseif self.gates == 4 then
      outputAnd(self.andTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))][toIndex(object.getInputNodeLevel(self.gateNode3))][toIndex(object.getInputNodeLevel(self.gateNode4))])
      outputOr(self.orTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))][toIndex(object.getInputNodeLevel(self.gateNode3))][toIndex(object.getInputNodeLevel(self.gateNode4))])
      outputXor(self.xorTruthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))][toIndex(object.getInputNodeLevel(self.gateNode3))][toIndex(object.getInputNodeLevel(self.gateNode4))])
    end
  end
  if storage.andState then
    storage.state = 2
  elseif storage.orState then
    storage.state = 1
  else
    storage.state = 0
  end
  animator.setAnimationState("switchState", storage.state)
end