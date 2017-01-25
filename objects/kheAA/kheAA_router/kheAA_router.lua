require "/scripts/kheAA/transferUtil.lua"
local deltatime = 0;

function init()
	transferUtil.init()
	storage.inputSlots = {};
	storage.outputSlots = {};
	storage.filterInverted = false;
	--storage.filterInverted = {false,false,false,false,false};
	storage.inContainers={}
	storage.outContainers={}
	message.setHandler("transferUtil.sendConfig", transferUtil.sendConfig)
	message.setHandler("setInverted", setInverted)
	message.setHandler("setInputSlots", setInputSlots)
	message.setHandler("setOutputSlots", setOutputSlots)
	object.setInteractive(true)
end

function update(dt)
	deltatime = deltatime + dt;
	if deltatime < 0.1 then
		return;
	end
	deltatime = 0;
	--transferUtil.updateInputs(1);
	local temp=transferUtil.updateInputs(1);
	transferUtil.updateOutputs(0);
	object.setOutputNodeLevel(0,temp)
	transferUtil.routeItems(storage);
end

function setInverted(a, b, inverted)
	storage.filterInverted = inverted;
end

function setInput(a, b, input)
	storage.input = object.getInputNodeIds(1);
	--storage.inputPos = world.entityPosition(input)
end

function setOutput(a, b, output)
	storage.output = object.getOutputNodeIds(0);
	--storage.outputPos = world.entityPosition(output)
end

function setInputSlots(a, b, slots)
	storage.inputSlots = slots;
end

function setOutputSlots(a, b, slots)
	storage.outputSlots = slots;
end