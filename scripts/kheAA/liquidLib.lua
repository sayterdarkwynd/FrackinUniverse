liquidLib = {}

function liquidLib.init()
	storage.liquids = storage.liquids or {}
	self.liquidOuts = self.liquidOuts or {}
	liquidLib.vars={}
	liquidLib.vars.inLiquidNode=config.getParameter("kheAA_inLiquidNode")--doesn't actually do anything, doesn't matter at this point.

	for i in pairs(storage.liquids) do
		if not root.liquidConfig(i) then
			storage.liquids[i]=nil
		end
	end
end

function liquidLib.itemToLiquidId(item)
	local itemBuffer=root.itemConfig(item)
	if itemBuffer.config.liquid then
		local liquidBuffer=root.liquidConfig(itemBuffer.config.liquid)
		if liquidBuffer.config.liquidId then
			return tonumber(liquidBuffer.config.liquidId)
		else
			return
		end
	else
		return
	end
end

function liquidLib.itemToLiquidLevel(item)
	local liquidBuffer=itemToLiquidId(item)
	return liquidBuffer and {liquidBuffer,item.count}
end

function liquidLib.liquidLevelToItem(liqLvl)
	return liquidLib.liquidToItem(liqLvl[1],liqLvl[2])
end

function liquidLib.liquidToItem(liquidId,level)
	local liquidBuffer=root.liquidConfig(liquidId)
	if liquidBuffer and liquidBuffer.config and liquidBuffer.config.itemDrop then
		return {count=level,parameters={},name=liquidBuffer.config.itemDrop}
	else
		return
	end
end

function liquidLib.dbg()
	local buffer={}
	for k,v in pairs(storage.liquids) do
		table.insert(buffer,{k,type(k),v,type(v)})
	end
	sb.logInfo("%s",buffer)
end

function liquidLib.canReceiveLiquid()
	if receiveLiquid==true then
		return true
	end
	return nil
end

function liquidLib.receiveLiquid(liquid)
	if not storage.liquids then storage.liquids={} end
	if (root.liquidConfig(liquid[1])) and (type(liquids[2])=="number") then
		storage.liquids[liquid[1]]=(storage.liquids[liquid[1]] or 0)+liquid[2]
	end
end

function liquidLib.doPump()
	if not transferUtil.powerLevel(transferUtil.vars.logicNode) then
		return
	end
	local pos = entity.position()
	local liquid = world.liquidAt(pos)
	if liquid == nil then
		for i,v in pairs(storage.liquids) do
			if root.liquidConfig(i) then
				if v > 0 then
					local spawned = world.spawnLiquid(pos, i, math.min(1, v))
					if spawned then
						storage.liquids[i] = v - math.min(1, v)
						break
					end
				end
			else
				storage.liquids[i]=nil
			end
		end
	elseif (storage.liquids[liquid[1]] ~= nil) and (storage.liquids[liquid[1]]>0) then
		if (liquid[2] < 1) and (storage.liquids[liquid[1]] > -1) then
			local spawned = world.spawnLiquid(pos, liquid[1], 1 - liquid[2])
			if spawned then
				storage.liquids[liquid[1]] = storage.liquids[liquid[1]] - (1 - liquid[2])
			end
		end
	end

	local items = world.containerItems(entity.id())

	if items ~= nil then
		for _,item in pairs(items) do
			if liquidLib.tryConsumeLiqitem(item) then break end
		end
	end

end

function liquidLib.tryConsumeLiqitem(item)
	local liquidId = liquidLib.itemToLiquidId(item)
	if type(liquidId) ~= "number" then
		return false
	end
	if storage.liquids[liquidId] == nil then
		storage.liquids[liquidId] = 0
	end
	if storage.liquids[liquidId] < 1 then
		item.count = 1
		local consumed = world.containerConsume(entity.id(), item)
		if consumed then
			storage.liquids[liquidId] = storage.liquids[liquidId] + 1
		end
	else
		return false
	end
	return true
end

function liquidLib.update(dt)
	self.liquidOuts={}
	if not liquidLib.vars.inLiquidNode then
		return
	end
	local tempList=object.getOutputNodeIds(liquidLib.vars.inLiquidNode)
	if tempList then
		for id in pairs(tempList) do
			local result=world.callScriptedEntity(id,"liquidLib.canReceiveLiquid")
			if result then
				self.liquidOuts[id]=world.entityPosition(id)
			end
		end
	end
end

function liquidLib.die()
	if storage.liquids then
		for id,count in pairs(storage.liquids) do
			local liquid=liquidLib.liquidToItem(id,count)

			if liquid then
				local buffer=liquid.count
				liquid.count=math.floor(liquid.count)
				buffer=buffer-liquid.count
				if liquid.count > 0 then
					world.spawnItem(liquid,entity.position())
				end
				if buffer > 0.0 then
					world.spawnLiquid(entity.position(),id,buffer)
				end
			else
				world.spawnLiquid(entity.position(),id,count)
			end
		end
	end
end
