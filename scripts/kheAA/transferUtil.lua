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
	transferUtil.vars.inDataNode=config.getParameter("kheAA_inDataNode")
	transferUtil.vars.outDataNode=config.getParameter("kheAA_outDataNode")
	transferUtil.vars.defaultMaxStack = root.assetJson("/items/defaultParameters.config").defaultMaxStack
	transferUtil.vars.itemDataCache = {}
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

--probably not a good idea to use. should I add a triggered reset of node lists on node connection change?
--least likely to cause disruption except in cases of explicit external timers
--it's this, or...anti-loop.
-- function transferUtil.onNodeConnectionChange(args)

-- end

-- function onNodeConnectionChange(args)
	-- transferUtil.onNodeConnectionChange(args)
-- end

function transferUtil.throwItemsAt(target,targetPos,item,drop)
	if item.count~=math.floor(item.count) or item.count<=0 then return false end
	local stackCap=handleCache(item).maxStack
	if item.count>stackCap then
		item.count=stackCap
	end
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
			--sb.logInfo("%s:%s reporting: %s at %s changed ID: %s",object.name(),entity.id(),target,targetPos,ping)
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
			--sb.logInfo("%s:%s reporting that %s at %s has a nil or zero container size",world.entityName(target),entity.id(),target,targetPos)
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

function transferUtil.updateNodeLists()
	local uInP=transferUtil.updateInputs()
	local uOutP=transferUtil.updateOutputs()
	return uInP and uOutP
end

function transferUtil.updateInputs()
	if not transferUtil.vars or not transferUtil.vars.didInit then
		transferUtil.init()
	end
	--later might find usefulness in knowing what prior data was?
	--transferUtil.vars.inputOld=transferUtil.vars.input
	transferUtil.vars.input={}
	--transferUtil.vars.inContainersOld=transferUtil.vars.inContainers
	transferUtil.vars.inContainers={}

	if self.disabled then return end
	if not transferUtil.vars.inDataNode then
		return false
	end

	transferUtil.vars.inputList=copy(object.getInputNodeIds(transferUtil.vars.inDataNode))
	local buffer={}
	for inputSource in pairs(transferUtil.vars.inputList) do
		local source=inputSource
		if source then
			local temp=world.callScriptedEntity(source,"transferUtil.sendContainerInputs")
			if temp ~= nil then
				for entId,position in pairs(temp) do
					buffer[entId]=position
				end
			end
		end
	end
	transferUtil.vars.inContainers=buffer
	return true
end

function transferUtil.updateOutputs()
	if not transferUtil.vars or not transferUtil.vars.didInit then
		transferUtil.init()
	end
	--later might find usefulness in knowing what prior data was?
	--transferUtil.vars.outputOld=transferUtil.vars.output
	transferUtil.vars.output={}
	--transferUtil.vars.outContainersOld=transferUtil.vars.outContainers
	transferUtil.vars.outContainers={}
	transferUtil.vars.upstreamCount=0

	if self.disabled then return end
	if not transferUtil.vars.outDataNode then
		return false
	end

	transferUtil.vars.outputList=copy(object.getOutputNodeIds(transferUtil.vars.outDataNode))
	local buffer={}
	for outputSource in pairs(transferUtil.vars.outputList) do
		local source=outputSource
		if source then
			-- this is for loop prevention, if a repeater forms a loop with another repeater, both clear their object lists and refuse to hold any data. prevents fossilization.
			if transferUtil.vars.inputList[source] and world.callScriptedEntity(source,"transferUtil.isRelayNode") then
				transferUtil.vars.inputList={}
				transferUtil.vars.outputList={}
				transferUtil.vars.outContainers={}
				transferUtil.vars.inContainers={}
				transferUtil.vars.upstreamCount=0
				return false
			end

			if world.callScriptedEntity(source,"transferUtil.checkUpstreamContainers") then
				transferUtil.vars.upstreamCount=transferUtil.vars.upstreamCount+1
			end

			local temp=world.callScriptedEntity(source,"transferUtil.sendContainerOutputs")
			if temp ~= nil then
				for entId,position in pairs(temp) do
					buffer[entId]=position
					transferUtil.vars.upstreamCount=transferUtil.vars.upstreamCount+1
				end
			end
		end
	end
	transferUtil.vars.outContainers=buffer
	return true
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

function transferUtil.checkUpstreamContainers()
	return (transferUtil.vars.upstreamCount or 0)>0
end

function transferUtil.hasUpstreamContainers()
	return util.tableSize(transferUtil.vars.outContainers)>0
end

--idea of "just update upstream when an object is removed"
--too messy, too prone to hiccups that could cause issues with machines.
--what if we remove a machine that is on the network from a DIFFERENT repeater?
-- function transferUtil.removeAput(id,preStr)
	-- for source in pairs(transferUtil.vars[preStr.."put"]) do
		-- if world.callScriptedEntity(source,"transferUtil.isRelayNode") then
			-- world.callScriptedEntity(source,"transferUtil.doRemoveAput",id,preStr)
		-- end
	-- end
-- end

-- function transferUtil.doRemoveInput(id,preStr)
	-- transferUtil.vars[preStr..""][id]=nil
-- end

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
	return transferUtil and transferUtil.vars and (not transferUtil.isRouterNode()) and transferUtil.vars.inContainers or {}
end

function transferUtil.sendContainerOutputs()
	return transferUtil and transferUtil.vars and (not transferUtil.isRouterNode()) and transferUtil.vars.outContainers or {}
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

function handleCache(item)
	if (not transferUtil.vars.itemDataCache[item.name])
	or (item.parameters.category and (item.parameters.category~=transferUtil.vars.itemDataCache[item.name].itemCat)) then

		local buffer=root.itemConfig(item)
		local buffer2={}
		if item.name == "sapling" then
			buffer2.itemCat=item.name
		elseif buffer.parameters.currency or buffer.config.currency or item.currency then
			buffer2.itemCat="currency"
		elseif buffer.parameters and buffer.parameters.category then
			buffer2.itemCat=buffer.parameters.category
		elseif buffer.config.category then
			buffer2.itemCat=buffer.config.category
		elseif buffer.config.category then
			buffer2.itemCat=buffer.config.category
		elseif buffer.category then
			buffer2.itemCat=buffer.category
		elseif buffer.config.projectileType then
			buffer2.itemCat="throwableitem"
		--[[elseif buffer.config.itemTags then
			for _,tag in pairs(buffer.config.itemTags) do

			end]]
		end
		buffer2.maxStack=buffer.parameters.maxStack or buffer.config.maxStack or transferUtil.vars.defaultMaxStack
		transferUtil.vars.itemDataCache[item.name]=buffer2
	end
	return transferUtil.vars.itemDataCache[item.name]
end

function transferUtil.getType(item)
	if not item.name then
		return "unhandled"
	end
	local itemCache=handleCache(item)
	if itemCache and itemCache.itemCat then
		return string.lower(itemCache.itemCat)
	elseif not unhandled[item.name] then
		--sb.logInfo("Unhandled Item:\n%s\n%s",item,itemCache)
		unhandled[item.name]=true
	end
	return "unhandled"
end

function transferUtil.leftToList(input)
	local buffer={}
	for k in pairs(input) do
		buffer[#buffer + 1]=k
	end
	return buffer
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

function transferUtil.isRelayNode()
	return transferUtil.vars.isRelayNode
end

function transferUtil.isRouterNode()
	return transferUtil.vars.isRouter
end

function dbg(args)
	sb.logInfo(sb.printJson(args))
end
