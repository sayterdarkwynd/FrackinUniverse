function isn_getAllDevicesConnectedOnNode(node,direction)
	if node == nil then return nil end
	
	local nodeID
	if direction == "output" then nodeID = object.getOutputNodeIds(node)
	else nodeID = object.getInputNodeIds(node) end
	if nodeID == nil then
		return nil
	end
	
	local devices = { }
	for key, _ in pairs(nodeID) do
		table.insert(devices,key)
	end
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
	for key, value in pairs(object.getOutputNodeIds(node)) do
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

function isn_effectTypesInRange(effect,tilerange,types,duration)
	local targetlist = world.entityQuery(entity.position(),tilerange,{includedTypes=types})
	for key, value in pairs(targetlist) do
		world.sendEntityMessage(value,"applyStatusEffect",effect,duration)
	end
end

function isn_effectPlayersInRange(effect,tilerange,duration)
	isn_effectTypesInRange(effect,tilerange,{"player"},duration)
end

function isn_effectAllInRange(effect,tilerange,duration)
	isn_effectTypesInRange(effect,tilerange,{"creature"},duration)
end

function isn_projectileTypesInRange(projtype,tilerange,types)
	local targetlist = world.entityQuery(entity.position(),tilerange,{includedTypes=types})
	for key, value in pairs(targetlist) do
		world.spawnProjectile(projtype, world.entityPosition(value), entity.id())
	end
end

function isn_projectilePlayersInRange(projtype,tilerange)
	isn_projectileTypesInRange(projtype,tilerange,{"player"})
end

function isn_projectileAllInRange(projtype,tilerange)
	isn_projectileTypesInRange(projtype,tilerange,{"creature"})
end

function isn_projectileTypesInRangeParams(projtype,tilerange,params,types)
	local targetlist = world.entityQuery(entity.position(),tilerange,{includedTypes=types})
	for key, value in pairs(targetlist) do
		world.spawnProjectile(projtype, world.entityPosition(value), entity.id(),{0,0},false,params)
	end
end

function isn_projectilePlayersInRangeParams(projtype,tilerange,params)
	isn_projectileTypesInRangeParams(projtype,tilerange,params,{"player"})
end

function isn_projectileAllInRangeParams(projtype,tilerange,params)
	isn_projectileTypesInRangeParams(projtype,tilerange,params,{"creature"})
end

function isn_projectileTypesInRectangle(projtype,entpos,xwidth,yheight,types)
	local targetlist = world.entityQuery(entpos,{entpos[1]+xwidth, entpos[2]+yheight},{includedTypes=types})
	for key, value in pairs(targetlist) do
		world.spawnProjectile(projtype,world.entityPosition(value))
	end
end

function isn_projectilePlayersInRectangle(projtype,entpos,xwidth,yheight)
	isn_projectileTypesInRectangle(projtype,entpos,xwidth,yheight,{"player"})
end

function isn_projectileAllInRectangle(projtype,entpos,xwidth,yheight)
	isn_projectileTypesInRectangle(projtype,entpos,xwidth,yheight,{"creature"})
end
