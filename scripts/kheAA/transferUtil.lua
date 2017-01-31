require "/scripts/util.lua"
transferUtil={}
disabled=false
unhandled={}
--util.tableSize()
transferUtil.itemTypes = {}


function transferUtil.init()
	if storage==nil then
		storage={}
	end
	if storage.init==nil then
		storage.init=true
	end
	storage.position=entity.position()
	transferUtil.initTypes()
end

function transferUtil.initTypes()
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

function transferUtil.getAbsPos(position)
	pos=storage.position;
	return {world.xwrap(pos[1] + position[1]), pos[2] + position[2]};
end

function transferUtil.routeItems()
	if not (util.tableSize(storage.inContainers) > 0) then return end
	if not (util.tableSize(storage.outContainers) > 0) then return end
	for sourceContainer,_ in pairs(storage.inContainers) do
		local targetContainer=transferUtil.findNearest(sourceContainer,storage.outContainers)
		if targetContainer ~= nil then
			local sourceItems=world.containerItems(sourceContainer)
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
	for i2,_ in pairs(targetList) do
		if i2 ~= origin and i2 ~= nil then
		local spaces1=world.objectSpaces(i2)
		local spaces2=world.objectSpaces(origin)
		if spaces1 == nil then return end
		if spaces2 == nil then return end
		if #spaces1 == 0 then return end
		if #spaces2 == 0 then return end
		temp=world.magnitude(spaces1[1],spaces2[1])
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

function transferUtil.checkFilter(item)
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
--Public functions for interoperability


function receiveItem(item)
	return transferUtil.tryFitOutput(entity.id(),item)
end


function canReceiveItem(item)
	if storage.receiveItem~=nil then
		if item ~= nil then
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
