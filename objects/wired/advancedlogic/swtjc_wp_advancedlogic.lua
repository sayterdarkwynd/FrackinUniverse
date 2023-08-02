function init()
	object.setInteractive(false)
	if storage.state == nil then
		output(false)
	else
		--causes all outputs to be set to the last recorded state. wire states persist. pointless.
		--object.setAllOutputNodes(storage.state)
		if storage.state then
			animator.setAnimationState("switchState", "on")
		else
			animator.setAnimationState("switchState", "off")
		end
	end
	self.gates = config.getParameter("gates")
	self.truthtable = config.getParameter("truthtable")
	self.hasNotGate = config.getParameter("hasNotGate")
	if self.hasNotGate then
		self.notGateNode = config.getParameter("notGateNode")
		if self.notGateNode == nil then
			self.hasNotGate = false
		else
			--pointless.
			--object.setOutputNodeLevel(self.notGateNode, not state)
		end
	else
		self.hasNotGate = false
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

function output(state)
	if storage.state ~= state then
		storage.state = state
		object.setAllOutputNodes(state)
		if self.hasNotGate then
			object.setOutputNodeLevel(self.notGateNode, not state)
		end
		if state then
			animator.setAnimationState("switchState", "on")
		else
			animator.setAnimationState("switchState", "off")
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
	if not self.hasLatch or not object.isInputNodeConnected(self.latchNode) or object.getInputNodeLevel(self.latchNode) then
		if self.gates == 1 then
			output(self.truthtable[toIndex(object.getInputNodeLevel(self.gateNode1))])
		elseif self.gates == 2 then
			output(self.truthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))])
		elseif self.gates == 3 then
			output(self.truthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))][toIndex(object.getInputNodeLevel(self.gateNode3))])
		elseif self.gates == 4 then
			output(self.truthtable[toIndex(object.getInputNodeLevel(self.gateNode1))][toIndex(object.getInputNodeLevel(self.gateNode2))][toIndex(object.getInputNodeLevel(self.gateNode3))][toIndex(object.getInputNodeLevel(self.gateNode4))])
		end
	end
end
