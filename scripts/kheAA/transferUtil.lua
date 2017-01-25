transferUtil={}

function transferUtil.init()
	if storage.init==nil then
		storage={}
		storage.init=true
	end
	storage.position=entity.position()
end

transferUtil.itemtypes = {
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

function transferUtil.routeItems(storage)

	--[[if~= nil and target ~= nil and world.entityExists(source) and world.entityExists(target) then
		local items = world.containerItems(storage.input)
		if items ~= nil then
			if #storage.inputSlots > 0 then
				transferUtil.transferFromSlots(storage)
			else
				transferUtil.transferFromAnywhere(storage)
			end
		end
	end]]--
end


function transferUtil.tConjunct(t1,t2)
	--sb.logInfo(tostring(t1).."::::"..tostring(t2))
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
		--sb.logInfo(k1.."::::"..v1)
		beep=false
		for _,v1 in pairs(t1) do
			--sb.logInfo(k2..":::::"..v2)
			if(tonumber(v2)==tonumber(v1)) then
				beep=true
				--break;
			end
		end
		if not beep then
			--sb.logInfo("Inserting "..v2)
			table.insert(t1,v2)
		end
	end
	return t1;
end

function transferUtil.checkFilter(item,invert)
	--Inverted = Don't take
	local filterItems = world.containerItems(entity.id())
	local filters = false;
	for i,v in pairs(filterItems) do
		filters = true;
		if transferUtil.compareItems(v, item) then
			return invert == false;
		end
	end
	if filters == false then
		return true;
	end
	return filterItems;
end


function transferUtil.compareItems(itemA, itemB)
	if itemA == nil or itemB == nil then
		return false;
	end
	if itemA.name == itemB.name then
		return true;
	end
end

function transferUtil.transferFromAnywhere(source,target,items)
	for i,v in pairs(items) do
		local item = v;
		if checkFilter(item) then
			local success, amount = transferUtil.tryFitOutput(target,item);
				if success then
					world.containerConsumeAt(source, i - 1, amount)
					return;
			end
		end
	end
end

function transferUtil.transferFromSlots(source,target,items,slots)
	for i = 1, #slots do
		local item = items[slots[i]];
		if item ~= nil then
			if checkFilter(item) then
				local success, amount = transferUtil.tryFitOutput(target,item,slots);
				if success then
					world.containerConsumeAt(source, slots[i] - 1, amount)
					return;
				end
			end
		end
	end
end

function transferUtil.tryFitOutput(target,item,slots,drop)
	if drop==nil then
		drop=false
	end
	if slots==nil then
			local leftOverItems = world.containerAddItems(target, item)
			if leftOverItems == nil or leftOverItems.count ~= item.count then
				if leftOverItems == nil then
					return true, item.count;
				else
					if drop then 
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
	end
	if #slots > 0 then
		for i = 1, #slots do
			local leftOverItems = world.containerPutItemsAt(target, item, slots - 1)
			if leftOverItems == nil or leftOverItems.count ~= item.count then
				if leftOverItems == nil then
					return true, item.count;
				else
					return true, item.count - leftOverItems.count;
				end
			end
		end
	else
		local containerName = world.entityName(target);
		local containerConfig = root.itemConfig({name = containerName, count = 1})
		local slots = containerConfig.config.slotCount;
		if containerConfig ~= nil then
			for i = 1, slots do
				local leftOverItems = world.containerPutItemsAt(output, item, i - 1)
				if leftOverItems == nil or leftOverItems.count ~= item.count then
					if leftOverItems == nil then
						return true, item.count;
					else
						return true, item.count - leftOverItems.count;
					end
				end
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

function transferUtil.sendContainerInputs(node)
	if(transferUtil.powerLevel(node)) then
		if(storage.inContainers~=nil)then
			return storage.inContainers
		end
	end
	return(nil)
end

function transferUtil.sendContainerOutputs(node)
	if(transferUtil.powerLevel(node)) then
		if(storage.outContainers~=nil)then
			return storage.outContainers
		end
	end
	return(nil)
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
	if not transferUtil.powerLevel(powerNode,true) then
		storage.input={}
		storage.inContainers={}
		return false
	end
	storage.input=object.getInputNodeIds(dataNode);
	for k,_ in pairs(storage.input) do
		result=world.callScriptedEntity(k,"transferUtil.sendContainerInputs");
		storage.inContainers=transferUtil.tConjunct(storage.inContainers,result)
	end
	return true
end

function transferUtil.updateOutputs(powerNode,dataNode)
	if dataNode==nil then dataNode=powerNode end
	if not transferUtil.powerLevel(powerNode,true) then
		storage.output={}
		storage.outContainers={}
		return
	end
	storage.output=object.getOutputNodeIds(dataNode);
	for k,_ in pairs(storage.output) do
		result=world.callScriptedEntity(k,"transferUtil.sendContainerOutputs");
		storage.outContainers=transferUtil.tConjunct(storage.outContainers,result)
	end
end



--Public functions for interoperability


function receiveItem(itemDescriptor)
	return transferUtil.tryFitOutput(entity.id(),itemDescriptor)
end


function canReceiveItem(itemDescriptor)
	if storage.receiveItem~=nil then
		if transferUtil.powerLevel(0) and itemDescriptor ~= nil then
			if storage.receiveItem==true then
				if storage.filterType~=nil then
					if transferUtil.getType(itemDescriptor) ~= storage.filterType then
						return false
					else
						return true
					end
				end
				return true
			end
		end
	end
	return nil
end



function transferUtil.getType(itemDescriptor)
	local itemRoot = root.itemConfig(itemDescriptor.name)
	local itemCat=string.tolower(itemRoot.category)
	if itemCat~=nil then
		return itemCat
	end
	return "generic"
end

function transferUtil.getCategory(itemDescriptor)
	local itemCat=transferUtil.getType(itemDescriptor)
	for k,group in pairs(transferUtil.itemTypes) do
		for k,v in pairs(group.options) do 
			if v==itemType then 
				return group.group
			end
		end
	end
	return "generic"
end
