require "/scripts/util.lua"
transferUtil={}
disabled=false
unhandled={}
--util.tableSize()
transferUtil.itemTypes = nil

--[[

if deltaTime > 1 then
	deltaTime=0
	transferUtil.loadSelfContainer()
else
	deltaTime=deltaTime+dt
end

]]

function transferUtil.init()
	if storage==nil then
		storage={}
	end
	if storage.init==nil then
		storage.init=true
	end
	storage.position=entity.position()
end

function transferUtil.initTypes()
	transferUtil.itemTypes={}
	transferUtil.itemTypes["generic"]={"foodjunk","junk","other","vehiclecontroller","generic", "coin", "celestialitem","quest"} 
	transferUtil.itemTypes["treasure"]={"bug","tech","techmanagement","largefossile","mysteriousreward","smallfossil","shiplicense","currency","upgradecomponent","tradingcard","trophy","actionfigure","artifact"}
	transferUtil.itemTypes["material"]={"block","liquid","platform","rail","railplatform","breakable","railpoint"} 
	transferUtil.itemTypes["tool"]={"tool","fishingrod","miningtool","flashlight","wiretool","beamminingtool","tillingtool","paintingbeamtool","harvestingtool","musicalinstrument","grapplinghook","thrownitem"}
	transferUtil.itemTypes["weapon"]={"assaultrifle","axe","boomerang","bow","broadsword","chakram","crossbow","dagger","fistweapon","grenadelauncher","hammer","machinepistol","pistol","rocketlauncher","shield","shortsword","shotgun","sniperrifle","spear","staff","wand","toy","uniqueweapon","whip","fu_upgrade","fu_warspear","fu_lance","fu_pierce","fu_scythe","quarterstaff","warblade","fu_keening"}
	transferUtil.itemTypes["armor"]={"headarmor", "chestarmor", "legsarmor", "backarmor","enviroprotectionpack"} 
	transferUtil.itemTypes["cosmeticarmor"]={"chestwear","legwear","headwear","backwear"}
	transferUtil.itemTypes["consumable"]={"drink","preparedfood","food","medicine"}
	transferUtil.itemTypes["books"]={"blueprint", "codex"}
	transferUtil.itemTypes["augments"]={"eppaugment","fishinglure","fishingreel","petcollar","clothingdye"}
	transferUtil.itemTypes["reagents"]={"craftingmaterial","cookingingredient","fuel","crafting"}
	transferUtil.itemTypes["building"]={"machinery","spawner","terraformer","trap","wire","light","furniture","decorative","door","fridgestorage","teleporter","teleportmarker","shippingcontainer"}
	transferUtil.itemTypes["farming"]={"seed","sapling","farmbeastegg","farmbeastfood","farmbeastfeed"}
end

function transferUtil.loadSelfContainer()
	storage.containerId=entity.id()
	storage.inContainers={}
	storage.outContainers={}
	storage.inContainers[storage.containerId]=transferUtil.spacePos2Rect(world.objectSpaces(storage.containerId),storage.position)
	storage.outContainers[storage.containerId]=transferUtil.spacePos2Rect(world.objectSpaces(storage.containerId),storage.position)
end

function transferUtil.getAbsPos(position)
	pos=storage.position;
	return {world.xwrap(pos[1] + position[1]), pos[2] + position[2]};
end

function transferUtil.routeItems()
	if util.tableSize(storage.inContainers) == 0 then return end
	if util.tableSize(storage.outContainers) == 0 then return end
	for sourceContainer,pos in pairs(storage.inContainers) do
		local targetContainer,targetPos=transferUtil.findNearest(sourceContainer,storage.outContainers)
		if targetContainer ~= nil then
			--[[if not world.regionActive(pos) then
				world.loadRegion(pos)
			end]]--
			local sourceItems=world.containerItems(sourceContainer)
			if sourceItems==nil then return end
			for index1,item in pairs(sourceItems) do
				if transferUtil.checkFilter(item) then
					if transferUtil.validInputSlot(index1) then
						local tempSize=world.containerSize(targetContainer)
						if util.tableSize(storage.outputSlots) > 0 then
							for index0=0,tempSize-1 do
								if transferUtil.tFirstIndex(index0+1,storage.outputSlots) > 0 then
									local leftOverItems=world.containerPutItemsAt(targetContainer,item,index0)
									if leftOverItems~=nil then
										world.containerTakeNumItemsAt(sourceContainer,index1-1,item.count-leftOverItems.count)
										item=leftOverItems
										break
									else
										world.containerTakeNumItemsAt(sourceContainer,index1-1,item.count)
										break
									end
								end
							end
						else
							local leftOverItems=world.containerAddItems(targetContainer,item)
							if leftOverItems~=nil then
								local tempQuantity=item.count-leftOverItems.count
								if tempQuantity > 0 then
									world.containerTakeNumItemsAt(sourceContainer,index1-1,tempQuantity)
									break
								end
							else
								world.containerTakeNumItemsAt(sourceContainer,index1-1,item.count)
							end
						end
					end
				end
			end
		end
	end
end

function transferUtil.validInputSlot(slot)
	if util.tableSize(storage.inputSlots) == 0 then return true end
	return transferUtil.tFirstIndex(slot,storage.inputSlots)>0
end

function transferUtil.findNearest(origin,targetList)
	local temp=nil
	local target=nil
	local distance=nil
	local targetBox
	for i2,pos in pairs(targetList) do
		if i2 ~= origin and i2 ~= nil then
		if world.entityExists(i2) and world.entityExists(origin) then
			local pos1=world.callScriptedEntity(i2,"entity.position")
			local pos2=world.callScriptedEntity(origin,"entity.position")
			temp=world.magnitude(pos1,pos2)
				if distance==nil then
					target=i2
					targetBox=pos
					distance=temp
				elseif distance > temp then
					target=i2
					targetBox=pos
					distance=temp
				end
			end
		end
	end
	return target,targetBox
end

function transferUtil.tFirstIndex(entry,t1)
	for k,v in pairs(t1) do
		if entry==v then
			return k
		end
	end
	return 0
end

function transferUtil.pos2Rect(pos,size)
	if size == nil then size = 0 end
	return({pos[1]-size,pos[2]-size,pos[1]+size,pos[2]+size})
end

function transferUtil.spacePos2Rect(spaces,pos)
	local minX
	local minY
	local maxX
	local maxY
	if spaces==nil then return nil end
	for _,pos in pairs(spaces) do
		if minX==nil then minX=pos[1]
		elseif minX > pos[1] then minX=pos[1]
		end
		if minY==nil then minY=pos[2]
		elseif minY > pos[2] then minX=pos[2]
		end
		if maxX==nil then maxX=pos[1]
		elseif maxX < pos[1] then maxX=pos[1]
		end
		if maxY==nil then maxY=pos[2]
		elseif maxY < pos[2] then maxY=pos[2]
		end
	end
	return {pos[1]+minX,pos[2]+minY,pos[1]+maxX,pos[2]+maxY}
end

function transferUtil.rect2Center(rect,isFloat)
	local buffer
	if isFloat then
		buffer={1.0,1.0}
	else
		buffer={1,1}
	end
	buffer[1]=buffer[1]*((rect[1]+rect[3])/2)
	buffer[2]=buffer[2]*((rect[2]+rect[4])/2)
	if isFloat then
		return buffer
	else
		return {util.round(buffer[1],0),util.round(buffer[2],0)}
	end
end

function transferUtil.spacePos2Center(spaces,pos)
	return transferUtil.rect2Center(transferUtil.spacePos2Rect(spaces,pos),true)
end

function transferUtil.checkFilter(item)
	if transferUtil.itemTypes==nil then
		transferUtil.initTypes()
	end
	routerItems=world.containerItems(entity.id())
	if #routerItems == 0 then
		return true
	end
	local buffer={}
	for k,v in pairs(routerItems) do
		buffer[k]=true
	end
	
	for slot,rItem in pairs(routerItems) do
		local fType=storage.filterType[slot]
		if fType == -1 then
			if not transferUtil.compareItems(rItem, item) then
				buffer[slot]=false
			end
		elseif fType==0 then
			if not transferUtil.compareTypes(rItem, item) then
				buffer[slot]=false
			end
		elseif fType==1 then
			if not transferUtil.compareCategories(rItem, item) then
				buffer[slot]=false
			end
		else
			sb.logError("TransferUtil.routeItems just failed hardcore! something got screwed up somewhere.")
			return false
		end
	end
	local result=false
	for slot,b in pairs(buffer) do
		if storage.filterInverted[slot] then
			if buffer[slot] then
				result=false
				break
			end
		else
			if buffer[slot] then
				result=true
			end
		end
	
	end
	return result
end


function transferUtil.compareItems(itemA, itemB)
	if itemA == nil or itemB == nil then
		return false;
	elseif itemA.name == itemB.name then
		return true;
	end
	return false

end

function transferUtil.compareTypes(itemA, itemB)
	if itemA == nil or itemB == nil then
		return false;
	end
	if transferUtil.getType(itemA) == transferUtil.getType(itemB) then
		return true;
	end
	return false
end
function transferUtil.compareCategories(itemA, itemB)
	if itemA == nil or itemB == nil then
		return false;
	end
	if transferUtil.getCategory(itemA) == transferUtil.getCategory(itemB) then
		return true;
	end
	return false
end

function transferUtil.tryFitOutput(target,item,drop)
	local leftOverItems = world.containerAddItems(target, item)
	if leftOverItems == nil or leftOverItems.count ~= item.count then
		if leftOverItems == nil then
			return true, item.count;
		else
			if drop==true then 
				temp=world.objectSpaces(target)
				if temp~=nil then
					world.spawnItem(item,temp[1])
				else
					world.spawnItem(item,entity.position())
				end
			else
				return true, item.count - leftOverItems.count;
			end
		end
	end
	return false;
end


function transferUtil.makeContainer(containerID)
	local container = {};
	container.id = containerID;
	return container;
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
	if(node==nil)then
		node=0
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


function transferUtil.updateInputs(dataNode)
	storage.input={}
	storage.inContainers={}
	storage.input=object.getInputNodeIds(dataNode);
	local buffer={}
	for k,v in pairs(storage.input) do
		local temp=world.callScriptedEntity(k,"transferUtil.sendContainerInputs")
		if temp ~= nil then
			for k2,v2 in pairs(temp) do
				buffer[k2]=v2
			end
		end
	end
	storage.inContainers=buffer
end

function transferUtil.updateOutputs(dataNode)
	storage.output={}
	storage.outContainers={}
	storage.output=object.getOutputNodeIds(dataNode);
	local buffer={}
	for k,v in pairs(storage.output) do
		local temp=world.callScriptedEntity(k,"transferUtil.sendContainerOutputs")
		if temp ~= nil then
			for k2,v2 in pairs(temp) do
				buffer[k2]=v2
			end
		end
	end
	storage.outContainers=buffer
end


function transferUtil.getType(item)
	local itemRoot = root.itemConfig(item.name)
	local itemCat
	if itemRoot.category ~= nil then
		itemCat=itemRoot.category
	elseif itemRoot.config.category ~= nil then
			itemCat=itemRoot.config.category
	elseif itemRoot.config.projectileType~=nil then
		itemCat="thrownitem"
	end
	if itemCat~=nil then
		return string.lower(itemCat)
	elseif unhandled[item.name]~=true then
		sb.logInfo(sb.printJson(itemRoot))
		unhandled[item.name]=true
	end
	return string.lower(item.name)
end

function transferUtil.getCategory(item)
	local itemCat=transferUtil.getType(item)
	for group,options in pairs(transferUtil.itemTypes) do
		for _,option in pairs(options) do
			option=string.lower(option)
			if(itemCat==option) then
				return string.lower(group)
			end
		end
	end
	return string.lower(item.name)
end



function dbg(args)
	sb.logInfo(sb.printJson(args))
end

