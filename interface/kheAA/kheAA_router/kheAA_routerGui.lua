require "/scripts/kheAA/transferUtil.lua"
local inputList = "inputSlotScrollArea.inputSlotList";
local outputList = "outputSlotScrollArea.outputSlotList";


function init()
	pipes = {};
	containers = {};
	currentQuery = nil;
	pos = world.entityPosition(pane.containerEntityId());
	myBox=pane.containerEntityId()
	widget.setSize("scanner.scanGrid", {250, 88})
	xOffset = 125;
	yOffset = 41;
	input = nil;
	output = nil;
	inputSlots = {};
	outputSlots = {};
	inverted = false;
	initialized = false;
	promise = world.sendEntityMessage(pane.containerEntityId(), "transferUtil.sendConfig")
	
end

function containerFound()
	return true;
end

function initialize(conf)
	input = conf.input;
	output = conf.output;
	inverted = conf.filterInverted;
	inputSlots = {};
	outputSlots = {};
	for i = 1, #conf.inputSlots do
		table.insert(inputSlots, {conf.inputSlots[i], -1})
	end
	for i = 1, #conf.outputSlots do
		table.insert(outputSlots, {conf.outputSlots[i], -1})
	end
	redrawInputSlotList()
	redrawOutputSlotList()
	updateCheckbox()


	refresh();
end

function refresh()
	if not myBox.inputNodeCount() then
		items={};
		refreshList();
		return
	end
	if not myBox.isInputNodeConnected(0) then
		items={};
		refreshList();
		return
	end
	for k,v in pairs (myBox.getInputNodeIds(0)) do
		if v>1 then
			result=world.callScriptedEntity(v,"transferUtil.sendContainerInputs",nil)
			if(result~=nil)then
				containerFound(transferUtil.makeContainer(k))
			end	
		end
	end
end

function update()
	if not initialized then
		if promise:finished() and promise:succeeded() then
			initialize(promise:result())
			initialized = true;
		elseif promise:finished() and not promise:succeeded() then
			promise = world.sendEntityMessage(pane.containerEntityId(), "transferUtil.sendConfig")
		end
		return;
	end
end

function updateCheckbox()
	if inverted == false then
		widget.setChecked("invertedCheckbox", false)
		widget.setText("invertedText", "Only take filtered items")
	else
		widget.setChecked("invertedCheckbox", true)
		widget.setText("invertedText", "Don't take filtered items")
	end
end

function invertedCheckbox( ... )
	inverted = not inverted;
	updateCheckbox();
	world.sendEntityMessage(pane.containerEntityId(), "setInverted", inverted)
end

function setOutput()
	local item = widget.getListSelected("scanner.scanGrid")
	if item ~= nil and containers[item] ~= nil then
		if containers[item][1] ~= output and containers[item][1] ~= input then
			output = containers[item][1];
			world.sendEntityMessage(pane.containerEntityId(), "setOutput", output)
			drawGrid();
		end
	end
end

function setInput()
	local item = widget.getListSelected("scanner.scanGrid")
	if item ~= nil and containers[item] ~= nil then
		if containers[item][1] ~= output and containers[item][1] ~= input then
			input = containers[item][1];
			world.sendEntityMessage(pane.containerEntityId(), "setInput", input)
			drawGrid();
		end
	end
end

function addInputSlot( ... )
	local text = widget.getText("inputSlotCount")
	if text ~= "" and tonumber(text) >= 0 then
		local slot = tonumber(text);
		for i = 1, #inputSlots do
			if inputSlots[i][1] == slot then
				return;
			end
		end
		local item = widget.addListItem(inputList);
		widget.setText(inputList .. "." .. item .. ".slotNr", slot .. "");
		table.insert(inputSlots, {slot, item})
		syncInputSlots();
	end
end

function addOutputSlot( ... )
	local text = widget.getText("outputSlotCount")
	if text ~= "" and tonumber(text) >= 0 then
		local slot = tonumber(text);
		for i = 1, #outputSlots do
			if outputSlots[i][1] == slot then
				return;
			end
		end
		local item = widget.addListItem(outputList);
		widget.setText(outputList .. "." .. item .. ".slotNr", slot .. "");
		table.insert(outputSlots, {slot, item})
		syncOutputSlots();
	end
end

function subInputSlot( ... )
	local item = widget.getListSelected(inputList)
	if item ~= nil then
		for i = 1, #inputSlots do
			if inputSlots[i][2] == item then
				table.remove(inputSlots, i)
				syncInputSlots();
				redrawInputSlotList()
				return;
			end
		end
	end
end

function redrawInputSlotList()
	widget.clearListItems(inputList)
	for i = 1, #inputSlots do
		local item = widget.addListItem(inputList);
		widget.setText(inputList .. "." .. item .. ".slotNr", inputSlots[i][1] .. "");
		inputSlots[i][2] = item;
	end
end

function subOutputSlot( ... )
	local item = widget.getListSelected(outputList)
	if item ~= nil then
		for i = 1, #outputSlots do
			if outputSlots[i][2] == item then
				table.remove(outputSlots, i)
				syncOutputSlots();
				redrawOutputSlotList()
				return;
			end
		end
	end
end

function redrawOutputSlotList()
	widget.clearListItems(outputList)
	for i = 1, #outputSlots do
		local item = widget.addListItem(outputList);
		widget.setText(outputList .. "." .. item .. ".slotNr", outputSlots[i][1] .. "");
		outputSlots[i][2] = item;
	end
end

function syncInputSlots( ... )
	local slots = {};
	for i = 1, #inputSlots do
		table.insert(slots, inputSlots[i][1]);
	end
	world.sendEntityMessage(pane.containerEntityId(), "setInputSlots", slots);
end

function syncOutputSlots( ... )
	local slots = {};
	for i = 1, #outputSlots do
		table.insert(slots, outputSlots[i][1]);
	end
	world.sendEntityMessage(pane.containerEntityId(), "setOutputSlots", slots);
end

function reset( ... )
	input = nil;
	output = nil;
	world.sendEntityMessage(pane.containerEntityId(), "setInput", input)
	world.sendEntityMessage(pane.containerEntityId(), "setOutput", output)
	drawGrid();
end