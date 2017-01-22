function init()
  entity.setInteractive(false)
  storage.state = 0
  entity.setAnimationState("switchState", storage.state)

  self.andGateNode = entity.configParameter("andGateNode")
  self.orGateNode = entity.configParameter("orGateNode")
  self.xorGateNode = entity.configParameter("xorGateNode")
  self.nandGateNode = entity.configParameter("nandGateNode")
  self.norGateNode = entity.configParameter("norGateNode")
  self.nxorGateNode = entity.configParameter("nxorGateNode")

  if storage.andState == nil then
    outputAnd(false)
  else
    entity.setOutboundNodeLevel(self.andGateNode, storage.andState)
    entity.setOutboundNodeLevel(self.nandGateNode, not storage.andState)
  end
  if storage.orState == nil then
    outputOr(false)
  else
    entity.setOutboundNodeLevel(self.orGateNode, storage.orState)
    entity.setOutboundNodeLevel(self.norGateNode, not storage.orState)
  end
  if storage.xorState == nil then
    outputXor(false)
  else
    entity.setOutboundNodeLevel(self.xorGateNode, storage.xorState)
    entity.setOutboundNodeLevel(self.nxorGateNode, not storage.xorState)
  end

  self.gates = entity.configParameter("gates")
  self.andTruthtable = entity.configParameter("andTruthtable")
  self.orTruthtable = entity.configParameter("orTruthtable")
  self.xorTruthtable = entity.configParameter("xorTruthtable")

  self.hasLatch = entity.configParameter("hasLatch")
  if self.hasLatch then
    self.latchNode = entity.configParameter("latchNode")
    if self.latchNode == nil then
      self.hasLatch = false
    end
  else
    self.hasLatch = false
  end

  if self.gates >= 1 then
    self.gateNode1 = entity.configParameter("gateNode1")
    if self.gates >= 2 then
      self.gateNode2 = entity.configParameter("gateNode2")
      if self.gates >= 3 then
        self.gateNode3 = entity.configParameter("gateNode3")
        if self.gates >= 4 then
          self.gateNode4 = entity.configParameter("gateNode4")
          self.gates = 4
        end
      end
    end
  end
end

function outputAnd(state)
  if storage.andState ~= state then
    storage.andState = state
    entity.setOutboundNodeLevel(self.andGateNode, state)
    entity.setOutboundNodeLevel(self.nandGateNode, not state)
  end
end

function outputOr(state)
  if storage.orState ~= state then
    storage.orState = state
    entity.setOutboundNodeLevel(self.orGateNode, state)
    entity.setOutboundNodeLevel(self.norGateNode, not state)
  end
end

function outputXor(state)
  if storage.xorState ~= state then
    storage.xorState = state
    entity.setOutboundNodeLevel(self.xorGateNode, state)
    entity.setOutboundNodeLevel(self.nxorGateNode, not state)
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
  if not self.hasLatch or not entity.isInboundNodeConnected(self.latchNode) or entity.getInboundNodeLevel(self.latchNode) then
    if self.gates == 1 then
      outputAnd(self.andTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))])
      outputOr(self.orTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))])
      outputXor(self.xorTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))])
    elseif self.gates == 2 then
      outputAnd(self.andTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))])
      outputOr(self.orTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))])
      outputXor(self.xorTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))])
    elseif self.gates == 3 then
      outputAnd(self.andTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))][toIndex(entity.getInboundNodeLevel(self.gateNode3))])
      outputOr(self.orTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))][toIndex(entity.getInboundNodeLevel(self.gateNode3))])
      outputXor(self.xorTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))][toIndex(entity.getInboundNodeLevel(self.gateNode3))])
    elseif self.gates == 4 then
      outputAnd(self.andTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))][toIndex(entity.getInboundNodeLevel(self.gateNode3))][toIndex(entity.getInboundNodeLevel(self.gateNode4))])
      outputOr(self.orTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))][toIndex(entity.getInboundNodeLevel(self.gateNode3))][toIndex(entity.getInboundNodeLevel(self.gateNode4))])
      outputXor(self.xorTruthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))][toIndex(entity.getInboundNodeLevel(self.gateNode3))][toIndex(entity.getInboundNodeLevel(self.gateNode4))])
    end
  end
  if storage.andState then
    storage.state = 2
  elseif storage.orState then
    storage.state = 1
  else
    storage.state = 0
  end
  entity.setAnimationState("switchState", storage.state)
end