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
	storage.position=entity.position()
end

function transferUtil.initTypes()
	transferUtil.itemTypes={}
	transferUtil.itemTypes["bee"]={"queen","drone"}
	transferUtil.itemTypes["treasure"]={"coin", "celestialitem","vehiclecontroller","bug","largefossil","mysteriousreward","smallfossil","shiplicense","currency","upgradecomponent","tradingcard","trophy","actionfigure","artifact"}
	transferUtil.itemTypes["material"]={"block","liquid","platform","breakable"} 
	transferUtil.itemTypes["rail"]={"rail","railplatform","railpoint"} 
	transferUtil.itemTypes["tool"]={"tool","fishingrod","miningtool","flashlight","wiretool","beamminingtool","tillingtool","paintingbeamtool","harvestingtool","musicalinstrument","grapplinghook","thrownitem"}
	transferUtil.itemTypes["weapon"]={"swtjc_ewg_beamPistol","swtjc_ewg_revolver","swtjc_ewg_submachineGun","swtjc_ewg_battleRifle","swtjc_ewg_squadAutomaticWeapon","swtjc_ewg_beamRifle","swtjc_ewg_antiMaterialRifle","swtjc_ewg_sawedOffShotgun","swtjc_ewg_autoShotgun","swtjc_ewg_flakCannon","swtjc_ewg_multiGrenadeLauncher","swtjc_ewg_miniRocketLauncher","^#e43774;Upgradeable Weapon^reset;","assaultrifle","axe","boomerang","bow","broadsword","chakram","crossbow","dagger","fistweapon","grenadelauncher","hammer","machinepistol","pistol","rocketlauncher","shield","shortsword","shotgun","sniperrifle","spear","staff","wand","toy","uniqueweapon","whip","fu_upgrade","fu_warspear","fu_lance","fu_pierce","fu_scythe","quarterstaff","warblade","fu_keening", "xbow", "longsword", "greataxe","rapier","shortspear","katana","scythe", "mace", "lance", "energy", "magnorbs", "bioweapon","plasma","flamethrower","liquidGun","mininglaser","upgradeable","upgradeableTool","sniperrifle","rifle","elder" }
	transferUtil.itemTypes["consumable"]={"drink","preparedfood","food","medicine"}
	transferUtil.itemTypes["augments"]={"eppaugment","fishinglure","fishingreel","petcollar","clothingdye"}
	transferUtil.itemTypes["building"]={"techmanagement","crafting","machinery","spawner","terraformer","trap","wire","light","furniture","decorative","door","fridgestorage","teleporter","teleportmarker","shippingcontainer","storage"}
	transferUtil.itemTypes["farming"]={"seed","sapling","farmbeastegg","farmbeastfood","farmbeastfeed"}
	transferUtil.itemTypes["armor"]={"headarmor", "chestarmor", "legsarmor", "backarmor","headarmour", "chestarmour", "legsarmour", "backarmour","enviroprotectionpack", "t1armor", "t1armoru", "t2armor", "t2armoru", "t3armor", "t3armoru", "t4armor", "t4armoru", "t5armor", "t5armoru", "t6armor", "t6armoru", "t7armor", "t7armoru", "t8armor", "t8armoru"} 
	transferUtil.itemTypes["cosmeticarmor"]={"chestwear","legwear","headwear","backwear"}
	transferUtil.itemTypes["reagents"]={"craftingmaterial","cookingingredient","fuel"}
	transferUtil.itemTypes["books"]={"blueprint", "codex"}
	transferUtil.itemTypes["generic"]={"foodjunk","junk","other","generic","quest","tech"} 
end


function transferUtil.routeItems()
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
				if sourceItems ~= nil then 
					for indexIn,item in pairs(sourceItems) do
						if transferUtil.checkFilter(item) then
							if transferUtil.validInputSlot(indexIn) then
								if util.tableSize(storage.outputSlots) > 0 then
									for indexOut=1,world.containerSize(targetContainer) do
										if transferUtil.validOutputSlot(indexOut) then
											local leftOverItems=world.containerPutItemsAt(targetContainer,item,indexOut-1)
											if leftOverItems~=nil then
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
									if leftOverItems~=nil then
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

function transferUtil.updateInputs(dataNode)
	storage.input={}
	storage.inContainers={}
	storage.input=object.getInputNodeIds(dataNode);
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

function transferUtil.updateOutputs(dataNode)
	storage.output={}
	storage.outContainers={}
	storage.output=object.getOutputNodeIds(dataNode);
	local buffer={}
	for outputSource,nodeValue in pairs(storage.output) do
		local temp=world.callScriptedEntity(outputSource,"transferUtil.sendContainerOutputs")
		if temp ~= nil then
			for entId,position in pairs(temp) do
				buffer[entId]=position
			end
		end
	end
	storage.outContainers=buffer
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
			else
				result=true
			end
		else
			if buffer[slot] then
				result=true
			end
		end
	
	end
	return result
end

function transferUtil.findNearest(source,sourcePos,targetList)
	local temp=nil
	local target=nil
	local distance=nil
	local targetPos=nil
	if source == nil or targetList == nil then
		return nil
	elseif util.tableSize(targetList) == 0 then
		return nil
	end
	for i2,position in pairs(targetList) do
		if i2 ~= source and i2 ~= nil then
		temp=world.magnitude(position,sourcePos)
			if distance==nil then
				target=i2
				targetPos=position
				distance=temp
			elseif distance > temp then
				target=i2
				targetPos=position
				distance=temp
			end
		end
	end
	return target,targetPos
end


function transferUtil.pos2Rect(pos,size)
	if size == nil then size = 0 end
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

function transferUtil.getType(item)
	if item.name==nil then
		return "generic"
	elseif item.name == "sapling" then
		return item.name
	end
	local itemRoot = root.itemConfig(item)
	local itemCat
	if itemRoot.category ~= nil then
		itemCat=itemRoot.category
	elseif itemRoot.config.category ~= nil then
			itemCat=itemRoot.config.category
	elseif itemRoot.config.projectileType~=nil then
		itemCat="thrownitem"
	elseif itemRoot.config.itemTags then
		for _,tag in pairs(itemRoot.config.itemTags) do
		
		end
	end
	if itemCat~=nil then
		return string.lower(itemCat)
	elseif unhandled[item.name]~=true then
		sb.logInfo("Unhandled Item:\n%s",itemRoot)
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

