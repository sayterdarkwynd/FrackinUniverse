require '/scripts/power.lua'

function init()
	power.init()
	onInputNodeChange()
end

function setObjectOn()
	storage.on=not object.isInputNodeConnected(1) or object.getInputNodeLevel(1)
	animator.setAnimationState("switchState", storage.on and power.getTotalEnergy() > 0 and "on" or "off")
	return storage.on
end

function isPower()
	return setObjectOn()
end

function onNodeConnectionChange()
	setObjectOn()
	power.onNodeConnectionChange()
end

function onInputNodeChange(args)
	setObjectOn()
	for i=0,object.inputNodeCount()-1 do
		for value in pairs(object.getInputNodeIds(i)) do
			if world.callScriptedEntity(value,'isPower') then
				world.callScriptedEntity(value,'power.onNodeConnectionChange')
			end
		end
	end
	for i=0,object.outputNodeCount()-1 do
		for value in pairs(object.getOutputNodeIds(i)) do
			if world.callScriptedEntity(value,'isPower') then
				world.callScriptedEntity(value,'power.onNodeConnectionChange')
			end
		end
	end
end