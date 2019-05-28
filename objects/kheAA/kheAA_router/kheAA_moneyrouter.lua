require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	transferUtil.vars.inContainers={}
	transferUtil.vars.outContainers={}
	--[[message.setHandler("sendConfig", sendConfig)
	message.setHandler("setFilters", function (_, _, types) storage.filterType = types end)
	message.setHandler("setInverts", function (_, _, inverted) storage.filterInverted = inverted end)
	message.setHandler("setInvertSlots", function (_, _, inverted) storage.invertSlots = inverted end)
	message.setHandler("setInputSlots", function (msg, _, slots) storage.inputSlots = slots end)
	message.setHandler("setOutputSlots", function (msg, _, slots) storage.outputSlots = slots end)]]
	object.setInteractive(false)
end

function update(dt)
	deltatime = (deltatime or 0) + dt;
	if deltatime < 1 then
		return;
	end
	deltatime = 0;
	transferUtil.updateInputs();
	transferUtil.updateOutputs();
	
	if transferUtil.powerLevel(transferUtil.vars.logicNode) then
		routeMoney();
		object.setOutputNodeLevel(transferUtil.vars.outDataNode,util.tableSize(transferUtil.vars.inContainers)>0)
	else
		object.setOutputNodeLevel(transferUtil.vars.outDataNode,false)
	end
end

function routeMoney()
	if storage.disabled then return end
	if util.tableSize(transferUtil.vars.inContainers) == 0 then return end
	if util.tableSize(transferUtil.vars.outContainers) == 0 then return end

	for sourceContainer,sourcePos in pairs(transferUtil.vars.inContainers) do
		local sourceAwake,ping1=transferUtil.containerAwake(sourceContainer,sourcePos)
		if ping1 ~= nil then
			sourceContainer=ping1
		end
		for targetContainer,targetPos in pairs(transferUtil.vars.outContainers) do
			--local targetContainer,targetPos=transferUtil.findNearest(sourceContainer,sourcePos,transferUtil.vars.outContainers)
			local targetAwake,ping2=transferUtil.containerAwake(targetContainer,targetPos)
			if ping2 ~= nil then
				targetContainer=ping2
			end
			if targetAwake == true and sourceAwake == true then
				local sourceItems=world.containerItems(sourceContainer)
				for indexIn,item in pairs(sourceItems or {}) do
					--local conf = root.itemConfig(item.name)
					--sb.logInfo("%s",conf)
					--if conf.config.currency then
					if transferUtil.getType(item) == "currency" then
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