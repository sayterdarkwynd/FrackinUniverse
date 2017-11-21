function init()
  if storage.on == nil then
    storage.on = true
  end
end

function isPower()
  return storage.on
end

function onNodeConnectionChange()
  if not object.isInputNodeConnected(1) then
    storage.on = true
  end
  if storage.on then
    power.onNodeConnectionChange()
  end
end

function onInputNodeChange(args)
  if not object.isInputNodeConnected(1) then
    storage.on = true
	return
  end
  if args.node == 1 then
    storage.on = args.level
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
end