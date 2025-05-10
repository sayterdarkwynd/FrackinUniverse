require "/scripts/effectUtil.lua"

function init()
	if storage.init==nil then
		storage.init=true
		updateState()
		updateAnim()
	end
	self.effect=config.getParameter("generatorEffect")
	self.effectRange=config.getParameter("effectRange",30)
end

function update(dt)
	updateState()
	if storage.state then
		if self.effect then
			effectUtil.effectAllInRange(self.effect,self.effectRange,3)
		end
	end
	updateAnim()
end

function updateState()
	storage.state=(not (object.inputNodeCount() > 0)) or (not object.isInputNodeConnected(0)) or (object.getInputNodeLevel(0))
end

function updateAnim()
	if animator then
		animator.setAnimationState("samplingarrayanim", storage.state and "working" or "idle")
	end
end
