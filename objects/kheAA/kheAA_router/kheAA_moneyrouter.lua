require "/scripts/kheAA/transferUtil.lua"

function init()
	transferUtil.init()
	storage.inContainers={}
	storage.outContainers={}
	message.setHandler("sendConfig", sendConfig)
	message.setHandler("setFilters", function (_, _, types) storage.filterType = types end)
	message.setHandler("setInverts", function (_, _, inverted) storage.filterInverted = inverted end)
	message.setHandler("setInvertSlots", function (_, _, inverted) storage.invertSlots = inverted end)
	message.setHandler("setInputSlots", function (msg, _, slots) storage.inputSlots = slots end)
	message.setHandler("setOutputSlots", function (msg, _, slots) storage.outputSlots = slots end)
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
	
	if transferUtil.powerLevel(storage.logicNode) then
		transferUtil.routeMoney();
		object.setOutputNodeLevel(storage.outDataNode,util.tableSize(storage.inContainers)>0)
	else
		object.setOutputNodeLevel(storage.outDataNode,false)
	end
end