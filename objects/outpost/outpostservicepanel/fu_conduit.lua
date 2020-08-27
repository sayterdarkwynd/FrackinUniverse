require '/scripts/fupower.lua'

function init()
	power.init()
	onInputNodeChange()
end

function setObjectOn(iterations)
	storage.on=not object.isInputNodeConnected(1) or object.getInputNodeLevel(1)
	--animator.setAnimationState("switchState", storage.on and power.getTotalEnergy() > 0 and "on" or "off")
	return storage.on, iterations
end

function isPower(iterations)
	return setObjectOn(iterations)
end

function onNodeConnectionChange()
	setObjectOn(0)
	power.onNodeConnectionChange(nil,0)
end

function onInputNodeChange(args)
	setObjectOn(0)
	for i=0,object.inputNodeCount()-1 do
		for value in pairs(object.getInputNodeIds(i)) do
			if world.callScriptedEntity(value,'isPower',0) then
				world.callScriptedEntity(value,'power.onNodeConnectionChange',nil,0)
			end
		end
	end
	for i=0,object.outputNodeCount()-1 do
		for value in pairs(object.getOutputNodeIds(i)) do
			if world.callScriptedEntity(value,'isPower',0) then
				world.callScriptedEntity(value,'power.onNodeConnectionChange',nil,0)
			end
		end
	end
end