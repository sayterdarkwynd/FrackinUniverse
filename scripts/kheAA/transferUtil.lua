require "/scripts/util.lua"
transferUtil={}
disabled=false
unhandled={}
transferUtil.itemTypes = nil

--[[
function update(dt)
	if not transferUtilDeltaTime or (transferUtilDeltaTime > 1) then
		transferUtilDeltaTime=0
		transferUtil.loadSelfContainer()
	else
		transferUtilDeltaTime=transferUtilDeltaTime+dt
	end
end
]]

function transferUtil.init()
	if storage==nil then
		storage={}
	end
	--[[if storage.init==nil then
		storage.init=true
	end]]
	self.disabled=(entity.entityType() ~= "object") or nil
	if self.disabled then
		sb.logInfo("transferUtil automation functions are disabled on non-objects (current is \"%s\") for safety reasons.",entity.entityType())
		return
	end
	storage.position=storage.position or entity.position()
	transferUtil.vars={}
	transferUtil.vars.logicNode=config.getParameter("kheAA_logicNode")
	transferUtil.vars.inDataNode=config.getParameter("kheAA_inDataNode");
	transferUtil.vars.outDataNode=config.getParameter("kheAA_outDataNode");
	transferUtil.vars.didInit=true
end

function transferUtil.initTypes()
	transferUtil.itemTypes = root.assetJson("/scripts/kheAA/transferconfig.config").categories
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
	if self.disabled then return end
	if not targetBox then return end
	if not transferUtil.vars or not transferUtil.vars.didInit then
		transferUtil.init()
	end
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
			return true,item.count,true
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
		return true,item.count,true
	else
		return false
	end

	if world.containerSize(target) == nil or world.containerSize(target) == 0 then
		if drop then
			world.spawnItem(item,targetPos)
			return true,item.count,true
		else
			return false
		end
	end
	--world.containerStackItems() attempts to add items to an existing stack. fails otherwise. returns leftovers
	local leftOverItems = world.containerAddItems(target, item)
	if leftOverItems ~= nil then
		if drop then
			world.spawnItem(leftOverItems,targetPos)
			return true, item.count, true
		else
			return true,item.count-leftOverItems.count
		end
	end

	return true, item.count
end

function transferUtil.updateInputs()
	if not transferUtil.vars or not transferUtil.vars.didInit then
		transferUtil.init()
	end
	transferUtil.vars.input={}
	transferUtil.vars.inContainers={}
	if self.disabled then return end
	if not transferUtil.vars.inDataNode then
		return
	end
	transferUtil.vars.input=object.getInputNodeIds(transferUtil.vars.inDataNode);
	local buffer={}
	for inputSource in pairs(transferUtil.vars.input) do
		local temp=world.callScriptedEntity(inputSource,"transferUtil.sendContainerInputs")
		if temp ~= nil then
			for entId,position in pairs(temp) do
				buffer[entId]=position
			end
		end
	end
	transferUtil.vars.inContainers=buffer
end

function transferUtil.updateOutputs()
	if not transferUtil.vars or not transferUtil.vars.didInit then
		transferUtil.init()
	end
	transferUtil.vars.output={}
	transferUtil.vars.outContainers={}
	if self.disabled then return end
	if not transferUtil.vars.outDataNode then
		return
	end
	transferUtil.vars.output=object.getOutputNodeIds(transferUtil.vars.outDataNode);
	local buffer={}
	for outputSource in pairs(transferUtil.vars.output) do
		local temp=world.callScriptedEntity(outputSource,"transferUtil.sendContainerOutputs")
		if temp then
			for entId,position in pairs(temp) do
				buffer[entId]=position
			end
		end
	end
	transferUtil.vars.outContainers=buffer
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
	return transferUtil and transferUtil.vars and transferUtil.vars.inContainers or {}
end

function transferUtil.sendContainerOutputs()
	return transferUtil and transferUtil.vars and transferUtil.vars.outContainers or {}
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
		return "unhandled"
	elseif item.name == "sapling" then
		return item.name
	elseif item.currency then
		return "currency"
	end
	local itemRoot = root.itemConfig(item)--implement cache maybe?
	if itemRoot.config.currency then
		return "currency"
	end
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
		--sb.logInfo("Unhandled Item:\n%s",itemRoot)
		unhandled[item.name]=true
	end
	return "unhandled"
end

function transferUtil.getCategory(item)
	local itemCat=transferUtil.getType(item)
	return transferUtil.itemTypes[itemCat] or "unhandled"
end

function transferUtil.loadSelfContainer()
	if not transferUtil.vars or not transferUtil.vars.didInit then
		transferUtil.init()
	end
	transferUtil.vars.containerId=entity.id()
	transferUtil.unloadSelfContainer()
	transferUtil.vars.inContainers[transferUtil.vars.containerId]=storage.position
	transferUtil.vars.outContainers[transferUtil.vars.containerId]=storage.position
end

function transferUtil.unloadSelfContainer()
	if not transferUtil.vars or not transferUtil.vars.didInit then
		transferUtil.init()
	end
	transferUtil.vars.inContainers={}
	transferUtil.vars.outContainers={}
end

function dbg(args)
	sb.logInfo(sb.printJson(args))
end
