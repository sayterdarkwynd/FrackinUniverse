liquidLib = {}

function liquidLib.init()
	if storage.liquids == nil then
		storage.liquids = {};
	end
	if storage.liquidOuts == nil then
		storage.liquidOuts = {};
	end
	
	storage.inLiquidNode=config.getParameter("kheAA_inLiquidNode")--doesn't actually do anything, doesn't matter at this point.
end

function liquidLib.itemToLiquidId(item)
	return tonumber(root.liquidConfig(root.itemConfig(item).config.liquid).config.liquidId)
end

function liquidLib.itemToLiquidLevel(item)
	return {itemToLiquidId(item),item.count}
end

function liquidLib.liquidLevelToItem(liqLvl)
	return liquidLib.liquidToItem(liqLvl[1],liqLvl[2])
end

function liquidLib.liquidToItem(liquidId,level)
	return {count=level,parameters={},name=root.liquidConfig(liquidId).config.itemDrop}
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
	storage.liquids[liquid[1]]=(storage.liquids[liquid[1]] or 0)+liquid[2]
end



function liquidLib.doPump()
	if not transferUtil.powerLevel(storage.logicNode) then
		return;
	end
	local pos = entity.position();
	local liquid = world.liquidAt(pos);
	if liquid == nil then
		for i,v in pairs(storage.liquids) do
			if v > 0 then
				local spawned = world.spawnLiquid(pos, i, math.min(1, v));
				if spawned then
					storage.liquids[i] = v - math.min(1, v);
					break;
				end
			end
		end
	elseif (storage.liquids[liquid[1]] ~= nil) and (storage.liquids[liquid[1]]>0) then
		if (liquid[2] < 1) and (storage.liquids[liquid[1]] > -1) then
			local spawned = world.spawnLiquid(pos, liquid[1], 1 - liquid[2]);
			if spawned then
				storage.liquids[liquid[1]] = storage.liquids[liquid[1]] - (1 - liquid[2]);
			end
		end
	end
	
	local items = world.containerItems(entity.id());
	
	if items ~= nil then
		for slot,item in pairs(items) do
			if liquidLib.tryConsumeLiqitem(items[1]) then break end
		end
	end

end

function liquidLib.tryConsumeLiqitem(item)
	local liquidId = liquidLib.itemToLiquidId(item)
	if liquidId == nil then
		return false;
	end
	if storage.liquids[liquidId] == nil then
		storage.liquids[liquidId] = 0;
	end
	if storage.liquids[liquidId] < 1 then
		item.count = 1;
		local consumed = world.containerConsume(entity.id(), item);
		if consumed then
			storage.liquids[liquidId] = storage.liquids[liquidId] + 1;
		end
	else
		return false
	end
	return true
end

function liquidLib.update(dt)
	storage.liquidOuts={}
	if not storage.inLiquidNode then
		return
	end
	local tempList=object.getOutputNodeIds(storage.inLiquidNode)
	if tempList then
		for id,node in pairs(tempList) do
			local result=world.callScriptedEntity(id,"liquidLib.canReceiveLiquid")
			if result then
				storage.liquidOuts[id]=world.entityPosition(id)
			end
		end
	end
end


function liquidLib.die()
	if storage.liquids then
		for id,count in pairs(storage.liquids) do
			local liquid=liquidLib.liquidToItem(id,count)
			if liquid then
				world.spawnItem(liquid,entity.position())
			else
				world.spawnLiquid(entity.position(),id,count)
			end
		end
	end
end
