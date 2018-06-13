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
	storage.routerItems=world.containerItems(entity.id())
	transferUtil.updateInputs();
	transferUtil.updateOutputs();

	if transferUtil.powerLevel(storage.logicNode) then
		routeItems();
		object.setOutputNodeLevel(storage.outDataNode,util.tableSize(storage.inContainers)>0)
	else
		object.setOutputNodeLevel(storage.outDataNode,false)
	end
end

function initVars()
	storage.routerItems={}
	storage.inContainers={}
	storage.outContainers={}
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
	if storage.disabled then return end
	if util.tableSize(storage.inContainers) == 0 then return end

	local outputSizeG = util.tableSize(storage.outContainers)
	if outputSizeG == 0 then return end

	for sourceContainer,sourcePos in pairs(storage.inContainers) do
		local outputSize = outputSizeG
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
								if storage.roundRobin then
									-- Maximum amount per container
									storage.RRPKT = math.floor((item.count / outputSize) % mod)
									storage.RRPKT = math.floor(item.count / outputSize - storage.RRPKT)

									-- Amount left in the round-robin
									storage.RRAMT = item.count
									item.count = storage.RRPKT
								end
								item.count = item.count - (item.count % mod)
								local outputSlotCount = (storage.invertSlots[2] and (world.containerSize(targetContainer) - util.tableSize(storage.outputSlots))) or util.tableSize(storage.outputSlots)
								if outputSlotCount > 0 then
									if storage.roundRobinSlots then
										-- Maximum amount per slot
										storage.RRSPKT = math.floor((item.count / outputSlotCount) % mod)
										storage.RRSPKT = math.floor(item.count / outputSlotCount - storage.RRSPKT)

										-- Amount left in the round-robin
										storage.RRSAMT = item.count
										item.count = storage.RRSPKT
									end
									for indexOut=1,world.containerSize(targetContainer) do
										if transferUtil.validOutputSlot(indexOut) then
											local leftOverItems=world.containerPutItemsAt(targetContainer,item,indexOut-1)
											if leftOverItems then
												world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count-leftOverItems.count)
												item = leftOverItems
											else
												world.containerTakeNumItemsAt(sourceContainer,indexIn-1,item.count)
												if not storage.roundRobinSlots then
													break
												end
											end
										end
										if storage.roundRobinSlots then
											if storage.RRSAMT < storage.RRSPKT then break end
											storage.RRSAMT = storage.RRSAMT - storage.RRSPKT
											item.count = storage.RRSPKT
										end
										-- Count down on those output slots!
										outputSlotCount = outputSlotCount - 1
									end
									storage.RRSPKT = nil
									storage.RRSAMT = nil
								else
									--world.containerStackItems() attempts to add items to an existing stack. fails otherwise. returns leftovers
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
								if storage.roundRobin then
									storage.RRAMT = storage.RRAMT - storage.RRPKT
									item.count = storage.RRAMT
									storage.RRAMT = nil
									storage.RRPKT = nil
								end
							end
						end
					end
				end
			else
				--dbg{"naptime",targetContainer,targetPos,sourceContainer,sourcePos}
			end
			if storage.roundRobin then
				-- Count down on those outputs!
				outputSize = outputSize - 1
			end
		end
	end
end