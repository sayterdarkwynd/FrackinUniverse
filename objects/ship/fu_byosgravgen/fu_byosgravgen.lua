require "/scripts/effectUtil.lua"

function init()
	power()
end

function update(dt)
	if storage.state then
		effectUtil.effectAllInRange("fu_byosgravgenfield",config.getParameter("range"), 10)
	end
end

function onInputNodeChange()
	power()
end

function onNodeConnectionChange()
	power()
end

function power()
	storage.state=not object.isInputNodeConnected(0) or object.isInputNodeConnected(0) and object.getInputNodeLevel(0)
end