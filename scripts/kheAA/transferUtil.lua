require "/scripts/util.lua"
transferUtil={}
disabled=false
unhandled={}
transferUtil.itemTypes = nil

--[[
function update(dt)
	if deltaTime > 1 then
		deltaTime=0
		transferUtil.loadSelfContainer()
	else
		deltaTime=deltaTime+dt
	end
end
]]

function transferUtil.init()
	if storage==nil then
		storage={}
	end
	if storage.init==nil then
		storage.init=true
	end
	storage.disabled=(entity.entityType() ~= "object")
	if storage.disabled then
		sb.logInfo("transferUtil automation functions are disabled on non-objects (current is \"%s\") for safety reasons.",entityType.entityType())
		return
	end
	storage.position=entity.position()
	storage.logicNode=config.getParameter("kheAA_logicNode")
	storage.inDataNode=config.getParameter("kheAA_inDataNode");
	storage.outDataNode=config.getParameter("kheAA_outDataNode");
end

function transferUtil.initTypes()
	transferUtil.itemTypes = root.assetJson("/scripts/kheAA/transferconfig.config").categories
end


function transferUtil.routeItems()
	if storage.disabled then return end
	if util.tableSize(storage.inContainers) == 0 then return end
	if util.tableSize(storage.outContainers) == 0 then return end

	for sourceContainer,sourcePos in pairs(storage.inContainers) do
		local sourceAwake,ping1=transferUtil.containerAwake(sourceContainer,sourcePos)
		if ping1 ~= nil then
			sourceContainer=ping1
		end
		for targetContainer,targetPos in pairs(storage.outContainers) do
			--local targetContainer,targetPos=transferUtil.findNearest(sourceContainer,sourcePos,storage.outContainers)
			local targetAwake,ping2=transferUtil.containerAwake(targetContainer,targetPos)
			if ping2 ~= nil then
				targetContainer=ping2
			end
			if targetAwake == true and sourceAwake == true then
				local sourceItems=world.containerItems(sourceContainer)
				if sourceItems then
					for indexIn,item in pairs(sourceItems) do
						local pass,mod = transferUtil.checkFilter(item)
						if pass then
							if transferUtil.validInputSlot(indexIn) then
								item.count = item.count - (item.count % mod)
								if util.tableSize(storage.outputSlots) > 0 then
									for indexOut=1,world.containerSize(targetContainer) do
										if transferUtil.validOutputSlot(indexOut) then
											local leftOverItems=world.containerPutItemsAt(targetContainer,item,indexOut-1)
											if leftOverItems then
												world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count-leftOverItems.count)
												item=leftOverItems
											else
												world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count)
												break
											end
										end
									end
								else
									local leftOverItems=world.containerAddItems(targetContainer,item)
									if leftOverItems then
										local tempQuantity=item.count-leftOverItems.count
										if tempQuantity > 0 then
											world.containerTakeNumItemsAt(sourceContainer,indexIn-1,tempQuantity)
											--break
										end
									else
										world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count)
									end
								end
							end
						end
					end
				end
			else
				--dbg{"naptime",targetContainer,targetPos,sourceContainer,sourcePos}
			end
		end
	end
end



function transferUtil.routeMoney()
	if storage.disabled then return end
	if util.tableSize(storage.inContainers) == 0 then return end
	if util.tableSize(storage.outContainers) == 0 then return end

	for sourceContainer,sourcePos in pairs(storage.inContainers) do
		local sourceAwake,ping1=transferUtil.containerAwake(sourceContainer,sourcePos)
		if ping1 ~= nil then
			sourceContainer=ping1
		end
		for targetContainer,targetPos in pairs(storage.outContainers) do
			--local targetContainer,targetPos=transferUtil.findNearest(sourceContainer,sourcePos,storage.outContainers)
			local targetAwake,ping2=transferUtil.containerAwake(targetContainer,targetPos)
			if ping2 ~= nil then
				targetContainer=ping2
			end
			if targetAwake == true and sourceAwake == true then
				local sourceItems=world.containerItems(sourceContainer)
				for indexIn,item in pairs(sourceItems or {}) do
					local conf = root.itemConfig(item.name)
					--sb.logInfo("%s",conf)
					if conf.config.currency then
						local leftOverItems = world.containerAddItems(targetContainer,item)
						if leftOverItems then
							world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count-leftOverItems.count)
							item=leftOverItems
						else
							world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count)
							break
						end
					end
				end
			else
				--dbg{"naptime",targetContainer,targetPos,sourceContainer,sourcePos}
			end
		end
	end
end


function transferUtil.containerAwake(targetContainer,targetPos)
	if type(targetPos) ~= "table" then
		return nil,nil
	elseif util.tableSize(targetPos) > 2 then
		targetPos={targetPos[1],targetPos[2]}
	elseif util.tableSize(targetPos)<2 then
		return nil,nil
	end
	local awake=transferUtil.zoneAwake(transferUtil.pos2Rect(targetPos,0.1))
	if awake==nil then
		return nil,nil
	elseif awake then
		ping=world.objectAt(targetPos)
		if ping ~= nil then
			if ping ~= targetContainer then
				if world.containerSize(ping) ~= nil then
					return true, ping
				else
					return false,nil
				end
			else
				return true,nil
			end
		else
			return false,nil
		end
	end
	return nil,nil
end

function transferUtil.zoneAwake(targetBox)
	if storage.disabled then return end
	if type(targetBox) ~= "table" then
		dbg({"zoneawake failure, invalid input:",targetBox})
		return nil
	else
		if util.tableSize(targetBox) ~= 4 then
			dbg({"zoneawake failure, invalid input:",targetBox})
			return nil
		end
	end
	if not world.regionActive(targetBox) then
		world.loadRegion(targetBox)
	else
		return true
	end
	if world.regionActive(targetBox) then
		return true
	else
		return false
	end
end


function transferUtil.throwItemsAt(target,targetPos,item,drop)

	if item.count~=math.floor(item.count) or item.count<=0 then return false end

	drop=drop or false

	if target==nil and targetPos==nil then
		if drop then
			world.spawnItem(item,entity.position())
			return true,item.count
		else
			return false
		end
	end

	local awake,ping=transferUtil.containerAwake(target,targetPos)
	if awake then
		if ping ~= nil then
			target=ping
		end
	elseif drop then
		world.spawnItem(item,entity.position())
		return true,item.count
	else
		return false
	end

	if world.containerSize(target) == nil or world.containerSize(target) == 0 then
		if drop then
			world.spawnItem(item,targetPos)
			return true,item.count
		else
			return false
		end
	end

	local leftOverItems = world.containerAddItems(target, item)
	if leftOverItems ~= nil then
		if drop then
			world.spawnItem(leftOverItems,targetPos)
			return true, item.count
		else
			return true,item.count-leftOverItems.count
		end
	else
		return true, item.count
	end

	return false;

end

function transferUtil.updateInputs()
	storage.input={}
	storage.inContainers={}
	if storage.disabled then return end
	if not storage.inDataNode then
		return
	end
	storage.input=object.getInputNodeIds(storage.inDataNode);
	local buffer={}
	for inputSource,nodeValue in pairs(storage.input) do
		local temp=world.callScriptedEntity(inputSource,"transferUtil.sendContainerInputs")
		if temp ~= nil then
			for entId,position in pairs(temp) do
				buffer[entId]=position
			end
		end
	end
	storage.inContainers=buffer
end

function transferUtil.updateOutputs()
	storage.output={}
	storage.outContainers={}
	if storage.disabled then return end
	if not storage.outDataNode then
		return
	end
	storage.output=object.getOutputNodeIds(storage.outDataNode);
	local buffer={}
	for outputSource,nodeValue in pairs(storage.output) do
		local temp=world.callScriptedEntity(outputSource,"transferUtil.sendContainerOutputs")
		if temp then
			for entId,position in pairs(temp) do
				buffer[entId]=position
			end
		end
	end
	storage.outContainers=buffer
end

function transferUtil.checkFilter(item)
	if not transferUtil.itemTypes then
		transferUtil.initTypes()
	end
	routerItems=world.containerItems(entity.id())
	if #routerItems == 0 then
		return true
	end
	local invertcheck = nil     -- Inverted conditions are match-all
	local noninvertcheck = nil  -- Non-inverted conditions are match-any
	local mod = nil             -- Stack comparison check is match-any (first match has priority)
	for slot,rItem in pairs(routerItems) do
		if not noninvertcheck or storage.filterInverted[slot] then
			local result = false
			local fType = storage.filterType[slot]
			if fType == -1 and transferUtil.compareItems(rItem, item) then
				result = true
			elseif fType == 0 and transferUtil.compareTypes(rItem, item) then
				result = true
			elseif fType == 1 and transferUtil.compareCategories(rItem, item) then
				result = true
			else
				result = false
			end
			if storage.filterInverted[slot] then
				result = not result
				invertcheck = result
				if not result then return false end
			else
				noninvertcheck = result
			end
			if result and not mod then
				mod = rItem.count
			end
		end
	end
	return (noninvertcheck and invertcheck)
			or (noninvertcheck == nil and invertcheck)
			or (noninvertcheck and invertcheck == nil),
			mod or 1
end

function transferUtil.findNearest(source,sourcePos,targetList)
	if not source or not targetList then
		return nil
	elseif util.tableSize(targetList) == 0 then
		return nil
	end
	local target = nil
	local distance = math.huge
	local targetPos = nil
	for i2,position in pairs(targetList) do
		if i2 ~= source then
			local dist = world.magnitude(position,sourcePos)
			if distance > dist then
				target=i2
				targetPos=position
				distance=dist
			end
		end
	end
	return target,targetPos
end


function transferUtil.pos2Rect(pos,size)
	if not size then size = 0 end
	return({pos[1]-size,pos[2]-size,pos[1]+size,pos[2]+size})
end

function transferUtil.tFirstIndex(entry,t1)
	for k,v in pairs(t1) do
		if entry==v then
			return k
		end
	end
	return 0
end

function transferUtil.validInputSlot(slot)
	if util.tableSize(storage.inputSlots) == 0 then return true end
	return (transferUtil.tFirstIndex(slot,storage.inputSlots)>0) == not storage.invertSlots[1]
end

function transferUtil.validOutputSlot(slot)
	if util.tableSize(storage.outputSlots) == 0 then return true end
	return (transferUtil.tFirstIndex(slot,storage.outputSlots)>0) == not storage.invertSlots[2]
end


function transferUtil.compareItems(itemA, itemB)
	if not itemA or not itemB then
		return false;
	elseif itemA.name == itemB.name then
		return true;
	end
	return false

end

function transferUtil.compareTypes(itemA, itemB)
	if not itemA or not itemB then
		return false;
	end
	if transferUtil.getType(itemA) == transferUtil.getType(itemB) then
		return true;
	end
	return false
end
function transferUtil.compareCategories(itemA, itemB)
	if not itemA or not itemB then
		return false;
	end
	if transferUtil.getCategory(itemA) == transferUtil.getCategory(itemB) then
		return true;
	end
	return false
end

function transferUtil.sendConfig()
	return storage;
end

function transferUtil.recvConfig(conf)
	storage=conf
end

function transferUtil.sendContainerInputs()
	return storage.inContainers
end

function transferUtil.sendContainerOutputs()
	return storage.outContainers
end

function transferUtil.powerLevel(node,explicit)
	if not node then
		return not explicit
	end
	if explicit==nil then
		explicit=false
	end
	if(object.inputNodeCount()<1)then
		return true
	end
	if object.isInputNodeConnected(node) then
		return object.getInputNodeLevel(node)
	else
		return not explicit
	end
end

function transferUtil.getType(item)
	if not item.name then
		return "generic"
	elseif item.name == "sapling" then
		return item.name
	elseif item.currency then
		return "currency"
	end
	local itemRoot = root.itemConfig(item)
	local itemCat
	if itemRoot.category then
		itemCat=itemRoot.category
	elseif itemRoot.config.category then
		itemCat=itemRoot.config.category
	elseif itemRoot.config.projectileType then
		itemCat="throwableitem"
	--[[elseif itemRoot.config.itemTags then
		for _,tag in pairs(itemRoot.config.itemTags) do

		end]]
	end
	if itemCat then
		return string.lower(itemCat)
	elseif not unhandled[item.name] then
		sb.logInfo("Unhandled Item:\n%s",itemRoot)
		unhandled[item.name]=true
	end
	return string.lower(item.name)
end

function transferUtil.getCategory(item)
	local itemCat=transferUtil.getType(item)
	--sb.logInfo("%s::%s",itemCat,string.lower(transferUtil.itemTypes[itemCat] or "generic"))
	return transferUtil.itemTypes[itemCat] or "generic"
end

function transferUtil.loadSelfContainer()
	storage.containerId=entity.id()
	storage.inContainers={}
	storage.outContainers={}
	storage.inContainers[storage.containerId]=storage.position
	storage.outContainers[storage.containerId]=storage.position
end

function transferUtil.getAbsPos(position,pos)
	return {world.xwrap(pos[1] + position[1]), pos[2] + position[2]};
end

function dbg(args)
	sb.logInfo(sb.printJson(args))
end
