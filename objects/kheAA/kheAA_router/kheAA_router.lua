require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	initVars()
	message.setHandler("sendConfig", sendConfig)
	message.setHandler("setFilters", function (_, _, types) storage.filterType = types end)
	message.setHandler("setInverts", function (_, _, inverted) storage.filterInverted = inverted end)
	message.setHandler("setInvertSlots", function (_, _, inverted) storage.invertSlots = inverted end)
	message.setHandler("setInputSlots", function (msg, _, slots) storage.inputSlots = slots end)
	message.setHandler("setOutputSlots", function (msg, _, slots) storage.outputSlots = slots end)
	message.setHandler("setRR", function (msg, _, rr) storage.roundRobin = rr end)
	message.setHandler("setRRS", function (msg, _, rr) storage.roundRobinSlots = rr end)
	object.setInteractive(true)
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return;
	end
	deltatime = 0;
	self.routerItems=world.containerItems(entity.id())
	transferUtil.updateInputs();
	transferUtil.updateOutputs();

	if transferUtil.powerLevel(transferUtil.vars.logicNode) then
		routeItems();
		object.setOutputNodeLevel(transferUtil.vars.outDataNode,util.tableSize(transferUtil.vars.inContainers)>0)
	else
		object.setOutputNodeLevel(transferUtil.vars.outDataNode,false)
	end
end

function initVars()
	self.routerItems={}
	transferUtil.vars.inContainers={}
	transferUtil.vars.outContainers={}
	if storage.inputSlots == nil then
		storage.inputSlots = {};
	end
	if storage.outputSlots == nil then
		storage.outputSlots = {};
	end
	if storage.filterInverted == nil then
		storage.filterInverted={}
		for i=1,5 do
			storage.filterInverted[i]=false;
		end
	end
	if storage.filterType == nil then
		storage.filterType={};
		for i=1,5 do
			storage.filterType[i]=-1;
		end
	end
	if not storage.invertSlots then
		storage.invertSlots={false,false}
	end
	self.init=true
end

function sendConfig()
	if not storage.inputSlots then
		storage.inputSlots = {};
	end
	if not storage.outputSlots then
		storage.outputSlots = {};
	end
	if not storage.filterInverted then
		storage.filterInverted={}
		for i=1,5 do
			storage.filterInverted[i]=false;
		end
	end
	if not storage.filterType then
		storage.filterType={};
		for i=1,5 do
			storage.filterType[i]=-1;
		end
	end
	if not storage.invertSlots then
		storage.invertSlots={false,false}
	end
	return {storage.inputSlots,storage.outputSlots,storage.filterInverted,storage.filterType,storage.invertSlots,storage.roundRobin or false,storage.roundRobinSlots or false}
end

function routeItems()
	if not self.init then return end
	if storage.disabled then return end
	if util.tableSize(transferUtil.vars.inContainers) == 0 then return end

	local outputSizeG = util.tableSize(transferUtil.vars.outContainers)
	if outputSizeG == 0 then return end

	for sourceContainer,sourcePos in pairs(transferUtil.vars.inContainers) do
		local outputSize = outputSizeG
		local sourceAwake,ping1=transferUtil.containerAwake(sourceContainer,sourcePos)
		if ping1 ~= nil then
			sourceContainer=ping1
		end
		
		local sourceItems=world.containerItems(sourceContainer)
		
		if sourceItems then
			for indexIn,item in pairs(sourceItems) do
				local pass,mod = checkFilter(item)
				if pass and (not storage.roundRobin or item.count>=(mod*outputSizeG)) then
					local outputSlotCountG = util.tableSize(storage.outputSlots)
					local originalCount=item.count
					local canRobinRoundSlots
					if storage.roundRobin then
						local buffer
						buffer=math.floor(item.count/outputSizeG)
						buffer=math.floor(buffer-(buffer%mod))
						item.count = math.floor(buffer)
					end
					if storage.roundRobinSlots and not storage.invertSlots[2] and outputSlotCountG>0 then
						local buffer
						buffer=math.floor(item.count/outputSlotCountG)
						buffer=math.floor(buffer-(buffer%mod))
						item.count = math.floor(buffer)
					end
					item.count = item.count - (item.count % mod)
					for targetContainer,targetPos in pairs(transferUtil.vars.outContainers) do
						local targetAwake,ping2=transferUtil.containerAwake(targetContainer,targetPos)
						if ping2 ~= nil then
							targetContainer=ping2
						end
						if targetAwake == true and sourceAwake == true then
							local containerSize=world.containerSize(targetContainer)
							local outputSlotCount=outputSlotCountG
							local outputSlotsBuffer={}
							
							
							for _,v in pairs(storage.outputSlots) do
								if v <= containerSize then
									table.insert(outputSlotsBuffer,v)
								end
							end
							
							outputSlotCount=util.tableSize(outputSlotsBuffer)
							
							
							local subCount=item.count
							if storage.roundRobinSlots and storage.invertSlots[2] then
								outputSlotCount=containerSize-outputSlotCount
								local buffer
								buffer=math.floor(item.count/outputSlotCount)
								buffer=math.floor(buffer-(buffer%mod))
								item.count = math.floor(buffer)
							end
							
							if validInputSlot(indexIn) then
								if outputSlotCount > 0 then
									local buffer=item.count * (storage.roundRobin and outputSize or 1) * (storage.roundRobinSlots and outputSlotCount or 1)
									if item.count>0 and buffer<=originalCount then
										for indexOut=1,containerSize do
											if validOutputSlot(indexOut) then
												local leftOverItems=world.containerPutItemsAt(targetContainer,item,indexOut-1)
												if leftOverItems then
													world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count-leftOverItems.count)
													originalCount=originalCount-(item.count-leftOverItems.count)
													if not storage.roundRobinSlots then
														if not storage.roundRobin then
															item = leftOverItems
														else
															break
														end
													end
												else
													world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count)
													originalCount=originalCount-item.count
													if not (storage.roundRobinSlots) then
														break
													end
												end
											end
										end
									end
								else
									if item.count>0 then
										--world.containerStackItems() attempts to add items to an existing stack. fails otherwise. returns leftovers
										local leftOverItems=world.containerAddItems(targetContainer,item)
										if leftOverItems then
											local tempQuantity=item.count-leftOverItems.count
											if tempQuantity > 0 then
												world.containerTakeNumItemsAt(sourceContainer,indexIn-1,tempQuantity)
												item=leftOverItems
											end
										else
											world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count)
											if not storage.roundRobin then
												item.count=0
											end
										end
									end
								end
							end
							if storage.roundRobinSlots and storage.invertSlots[2] then
								item.count=subCount
							end
						end
						outputSize=outputSize-1
					end
				end
			end
		end
	end
end

function checkFilter(item)
	if not transferUtil.itemTypes then
		transferUtil.initTypes()
	end
	routerItems=world.containerItems(entity.id())
	if util.tableSize(routerItems) == 0 then
		return true, 1
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


function validInputSlot(slot)
	if not storage.inputSlots then return false end
	if util.tableSize(storage.inputSlots) == 0 then return true end
	return (transferUtil.tFirstIndex(slot,storage.inputSlots)>0) == not storage.invertSlots[1]
end

function validOutputSlot(slot)
	if not storage.outputSlots then return false end
	if util.tableSize(storage.outputSlots) == 0 then return true end
	return (transferUtil.tFirstIndex(slot,storage.outputSlots)>0) == not storage.invertSlots[2]
end