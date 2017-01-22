function init()
  entity.setInteractive(false)
  if storage.state == nil then
    output(false)
  else
    entity.setAlloutputNodes(storage.state)
    if storage.state then
      entity.setAnimationState("switchState", "on")
    else
      entity.setAnimationState("switchState", "off")
    end
  end
  self.gates = entity.configParameter("gates")
  self.truthtable = entity.configParameter("truthtable")
  self.hasNotGate = entity.configParameter("hasNotGate")
  if self.hasNotGate then
    self.notGateNode = entity.configParameter("notGateNode")
    if self.notGateNode == nil then
      self.hasNotGate = false
    else
      entity.setOutboundNodeLevel(self.notGateNode, not state)
    end
  else
    self.hasNotGate = false
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

function output(state)
  if storage.state ~= state then
    storage.state = state
    entity.setAlloutputNodes(state)
    if self.hasNotGate then
      entity.setOutboundNodeLevel(self.notGateNode, not state)
    end
    if state then
      entity.setAnimationState("switchState", "on")
    else
      entity.setAnimationState("switchState", "off")
    end
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
      output(self.truthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))])
    elseif self.gates == 2 then
      output(self.truthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))])
    elseif self.gates == 3 then
      output(self.truthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))][toIndex(entity.getInboundNodeLevel(self.gateNode3))])
    elseif self.gates == 4 then
      output(self.truthtable[toIndex(entity.getInboundNodeLevel(self.gateNode1))][toIndex(entity.getInboundNodeLevel(self.gateNode2))][toIndex(entity.getInboundNodeLevel(self.gateNode3))][toIndex(entity.getInboundNodeLevel(self.gateNode4))])
    end
  end
end