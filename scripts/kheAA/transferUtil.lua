transferUtil={}
disabled=false
unhandled={}

function transferUtil.init()
	if storage==nil then
		storage={}
	end
	if storage.init==nil then
		storage.init=true
	end
	storage.position=entity.position()
end

transferUtil.itemTypes = {
	{group="generic",	options={"foodjunk","junk","other","vehiclecontroller","generic", "coin", "celestialitem","quest"} }, 
	{group="treasure",	options={"bug","tech","techmanagement","largefossile","mysteriousreward","smallfossil","shiplicense","currency","upgradecomponent","tradingcard","trophy","actionfigure","artifact"} },
	{group="material",	options={"block","liquid","platform","rail","railplatform","breakable","railpoint"} }, 
	{group="tool",	options={"tool","fishingrod","miningtool","flashlight","wiretool","beamminingtool","tillingtool","paintingbeamtool","harvestingtool","musicalinstrument","grapplinghook","thrownitem"} },
	{group="weapon",	options={"assaultrifle","axe","boomerang","bow","broadsword","chakram","crossbow","dagger","fistweapon","grenadelauncher","hammer","machinepistol","pistol","rocketlauncher","shield","shortsword","shotgun","sniperrifle","spear","staff","wand","toy","uniqueweapon","whip","fu_upgrade","fu_warspear","fu_lance","fu_pierce","fu_scythe","quarterstaff","warblade","fu_keening"} },
	{group="armor",	options={"headarmor", "chestarmor", "legsarmor", "backarmor","enviroprotectionpack"} }, 
	{group="cosmeticarmor",	options={"chestwear","legwear","headwear","backwear"} },
	{group="consumable",	options={"drink","preparedfood","food","medicine"} },
	{group="books",	options={"blueprint", "codex"} },
	{group="augments",	options={"eppaugment","fishinglure","fishingreel","petcollar","clothingdye"} },
	{group="reagents",	options={"craftingmaterial","cookingingredient","fuel","crafting"} },
	{group="building",	options={"machinery","spawner","terraformer","trap","wire","light","furniture","decorative","door","fridgestorage","teleporter","teleportmarker","shippingcontainer"} },
	{group="farming",	options={"seed","sapling","farmbeastegg","farmbeastfood","farmbeastfeed"} },
}

function transferUtil.getAbsPos(position)
	pos=storage.position;
	return {world.xwrap(pos[1] + position[1]), pos[2] + position[2]};
end

function transferUtil.routeItems()
	if #storage.inContainers < 1 then return end
	if #storage.outContainers < 1 then return end
	for _,sourceContainer in pairs(storage.inContainers) do
		local targetContainer=transferUtil.findNearest(sourceContainer,storage.outContainers)
		local sourceItems=world.containerItems(sourceContainer)
		for index1,item in pairs(sourceItems) do
			if transferUtil.checkFilter(item) then
				if transferUtil.validInputSlot(index1) then
					local tempSize=world.containerSize(targetContainer)
					if #storage.outputSlots > 0 then
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

function transferUtil.validInputSlot(slot)
	if #storage.inputSlots == 0 then return true end
	return (transferUtil.tFirstIndex(slot,storage.inputSlots)>0)
	--(#storage.inputSlots == 0) or (transferUtil.tFirstIndex(slot,storage.inputSlots)>0)
end

function transferUtil.findNearest(origin,targetList)
	local temp=nil
	local target=nil
	local distance=nil
	for _,i2 in pairs(targetList) do
		if i2~=origin then
		temp=world.magnitude(world.objectSpaces(i2)[1],world.objectSpaces(origin)[1])
			if distance==nil then
				target=i2
				distance=temp
			elseif distance > temp then
				target=i2
				distance=temp
			end
		end
	end
	return target
end

function transferUtil.tFirstIndex(entry,t1)
	for k,v in pairs(t1) do
		if entry==v then
			return k
		end
	end
	return 0
end

function transferUtil.tConjunct(t1,t2)
	if t2==nil then
		if(t1==nil) then
			return {};
		else
			return t1;
		end
	else
		if(t1==nil)then
			return t2;
		end
	end
	local beep;local meep;
	for _,v2 in pairs(t2) do
		beep=false
		for _,v1 in pairs(t1) do
			if(tonumber(v2)==tonumber(v1)) then
				beep=true
			end
		end
		if not beep then
			table.insert(t1,v2)
		end
	end
	return t1;
end

function transferUtil.checkFilter(item)
	routerItems=world.containerItems(entity.id())
	for slot,rItem in pairs(routerItems) do
		local invert=storage.filterInverted[slot]
		local fType=storage.filterType[slot]
		if fType == -1 then
			if transferUtil.compareItems(rItem, item) then
				if invert then
					return false
				end
			else
				if not invert then
					return false
				end
			end
		elseif fType==0 then
			if transferUtil.compareTypes(rItem, item) then
				if invert then
					return false
				end
			else
				if not invert then
					return false
				end
			end
		elseif fType==1 then
			if transferUtil.compareCategories(rItem, item) then
				if invert then
					return false
				end
			else
				if not invert then
					return false
				end
			end
		else
			return false
		end
	end
	return true
end


function transferUtil.compareItems(itemA, itemB)
	if itemA == nil or itemB == nil then
		return false;
	elseif itemA.name == itemB.name then
		return true;
	else
		return false
	end
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
	if(transferUtil.powerLevel(node)) then
		if(storage.inContainers~=nil)then
			return storage.inContainers
		end
	end
	return({})
end

function transferUtil.sendContainerOutputs()
	if outDataNode==nil then
		return
	end
	if(transferUtil.powerLevel(powerNode)) then
		if(storage.outContainers~=nil)then
			return storage.outContainers
		end
	end
	return({})
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
	--return true;
end


function transferUtil.updateInputs(powerNode,dataNode)
	if dataNode==nil then dataNode=powerNode end
	storage.input={}
	storage.inContainers={}
	storage.input=object.getInputNodeIds(dataNode);
	for k,_ in pairs(storage.input) do
		result=world.callScriptedEntity(k,"transferUtil.sendContainerInputs");
		storage.inContainers=transferUtil.tConjunct(storage.inContainers,result)
	end
	return true
end

function transferUtil.updateOutputs(powerNode,dataNode)
	if dataNode==nil then dataNode=powerNode end
	storage.output={}
	storage.outContainers={}
	storage.output=object.getOutputNodeIds(dataNode);
	for k,_ in pairs(storage.output) do
		result=world.callScriptedEntity(k,"transferUtil.sendContainerOutputs");
		storage.outContainers=transferUtil.tConjunct(storage.outContainers,result)
	end
	return true
end



--Public functions for interoperability


function receiveItem(item)
	return transferUtil.tryFitOutput(entity.id(),item)
end


function canReceiveItem(item)
	if storage.receiveItem~=nil then
		if transferUtil.powerLevel(0) and item ~= nil then
			if storage.receiveItem==true then
				if storage.filterType~=nil then
					return transferUtil.checkFilter(item)
				end
				return true
			end
		end
	end
	return nil
end



function transferUtil.getType(item)
	local itemRoot = root.itemConfig(item.name)
	local itemCat
	if itemRoot.category ~= nil then
		itemCat=itemRoot.category
	else
		if itemRoot.config.category ~= nil then
			itemCat=itemRoot.config.category
		end
		if itemRoot.config.projectileType~=nil then
			itemCat="thrownitem"
		end
	end
	if itemCat~=nil then
		return string.lower(itemCat)
	end
	if unhandled[item.name]~=true then
		sb.logInfo(sb.printJson(itemRoot))
		unhandled[item.name]=true
	end
	return "generic"
end

function transferUtil.getCategory(item)
	local itemCat=transferUtil.getType(item)
	for _,subset in pairs(transferUtil.itemTypes) do
		for _,v in pairs(subset.options) do
			v=string.lower(v)
			if v==itemCat then 
				return string.lower(subset.group)
			end
		end
	end
	return "generic"
end
