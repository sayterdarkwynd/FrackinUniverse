require "/scripts/effectUtil.lua"

function init()
	if storage.init==nil then
		storage.init=true
		storage.state=(not (object.inputNodeCount() > 0)) or (not object.isInputNodeConnected(0)) or (object.getInputNodeLevel(0))
	end
	self.effect=config.getParameter("generatorEffect")
	self.effectRange=config.getParameter("effectRange",30)
end

function update(dt)
	storage.state=(not (object.inputNodeCount() > 0)) or (not object.isInputNodeConnected(0)) or (object.getInputNodeLevel(0))
	if storage.state then
		if self.effect then
			effectUtil.effectAllInRange(self.effect,self.effectRange,3)
		end
	end
end