require "/scripts/kheAA/transferUtil.lua"
local deltatime = 0;

function init()
	transferUtil.init()
	initVars()
	message.setHandler("sendConfig", sendConfig)
	message.setHandler("setFilters", function (_, _, types) storage.filterType = types end)
	message.setHandler("setInverts", function (_, _, inverted) storage.filterInverted = inverted end)
	message.setHandler("setInputSlots", function (msg, _, slots) storage.inputSlots = slots end)
	message.setHandler("setOutputSlots", function (msg, _, slots) storage.outputSlots = slots end)
	object.setInteractive(true)
end

function update(dt)
	deltatime = deltatime + dt;
	if deltatime < 0.1 then
		return;
	end
	deltatime = 0;
	storage.routerItems=world.containerItems(entity.id())
	local temp=transferUtil.updateInputs(0,1);
	transferUtil.updateOutputs(0);
	object.setOutputNodeLevel(0,temp)
	storage.routerItems=world.containerItems(entity.id())
	transferUtil.routeItems();
end

function initVars()
	powerNode=0
	inDataNode=1
	outDataNode=0
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
end

function sendConfig()
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
	return({storage.inputSlots,storage.outputSlots,storage.filterInverted,storage.filterType})
end
