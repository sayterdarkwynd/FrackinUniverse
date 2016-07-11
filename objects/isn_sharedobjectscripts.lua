function isn_getAllDevicesConnectedOnNode(node,direction)
	---sb.logInfo("GENERAL GET DEVICE ON NODE DEBUG aka GGDOND")
	---sb.logInfo("GGDOND: called by " .. world.entityName(entity.id()))
	if node == nil then return nil end
	
	local nodeID
	if direction == "outbound" then nodeID = entity.getOutboundNodeIds(node)
	else nodeID = entity.getInboundNodeIds(node) end
	if nodeID == nil then
		---sb.logInfo("GGDOND: Node with ID " .. node .. " does not exist, terminating with nil")
		return nil
	end
	
	---local counter = 0
	local devices = { }
	---sb.logInfo("GGDOND: Iterating connected devices")
	for key, value in pairs(nodeID) do
		---sb.logInfo("GGDOND: counter at " .. counter)
		---sb.logInfo("GGDOND: key is " .. key)
		---for key2, value2 in pairs(value) do
		---	sb.logInfo("GGDOND: value's key is " .. key2)
		---	sb.logInfo("GGDOND: value's value is " .. value2)
		---end
		---table.insert(devices,value[1])
		table.insert(devices,key)
		---counter = counter + 1
	end
	---sb.logInfo("GGDOND: device count: " .. counter)
	---sb.logInfo("GENERAL GET DEVICE ON NODE DEBUG END")
	return devices
end

function isn_numericRange(number,minimum,maximum)
	if number > maximum then return maximum end
	if number < minimum then return minimum end
	return number
end

function isn_countDevicesConnectedOnOutboundNode(node)
	if not node then return 0 end
	local devicecount = 0
	for key, value in pairs(entity.getOutboundNodeIds(node)) do
		devicecount = devicecount + 1
	end
	return devicecount
end

function isn_getXPercentageOfY(x,y)
	if x == 0 then return 0 end
	if y == 0 then return 0 end
	return (x / y) * 100
end

function isn_getListLength(arg)
	local listlength = 0
	for _ in pairs(arg) do listlength = listlength + 1 end
	return listlength
end

function isn_projectileAllInRange(projtype,tilerange)
	local targetlist = world.playerQuery(entity.position(),tilerange)
	for key, value in pairs(targetlist) do
		world.spawnProjectile(projtype,world.entityPosition(value))
	end
end

function isn_projectileAllInRectangle(projtype,entpos,xwidth,yheight)
	local targetlist = world.playerQuery(entpos,{entpos[1]+xwidth, entpos[2]+yheight})
	for key, value in pairs(targetlist) do
		world.spawnProjectile(projtype,world.entityPosition(value))
	end
end